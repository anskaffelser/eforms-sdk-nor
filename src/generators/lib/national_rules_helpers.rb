#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

module NationalRulesHelpers
  # --- METADATA-HÅNDTERING ---

  # Rekursiv fjerning av metadata (alt som starter med _)
  def self.deep_prune_metadata!(object)
    case object
    when Hash
      object.delete_if { |k, _| k.to_s.start_with?('_') }
      object.each_value { |v| deep_prune_metadata!(v) }
    when Array
      object.each { |v| deep_prune_metadata!(v) }
    end
    object
  end

  # Kirurgisk fjerning (brukes i transpilatoren for å beholde spesifikke felt)
  def self.deep_prune_unwanted_metadata!(object, keep: ['_rule', '_rationale'])
    case object
    when Hash
      object.delete('_derivedRequirements')
      object.delete_if { |k, _| k.to_s.start_with?('_') && !keep.include?(k.to_s) }
      object.each_value { |v| deep_prune_unwanted_metadata!(v, keep: keep) }
    when Array
      object.each { |v| deep_prune_unwanted_metadata!(v, keep: keep) }
    end
    object
  end

  # --- VASKING AV TEKST OG XPATH ---

  # PROSA-VASK (Fjerner linjeskift og ekstra mellomrom i meldinger)
  def self.clean_prosa(content)
    return content unless content.is_a?(String)
    content.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ').strip
  end

  # AGGRESSIV XPATH-VASK (Normaliserer mellomrom rundt operatorer)
  def self.clean_xpath(content)
    return content unless content.is_a?(String)
  
    # 1. Kollaps alle linjeskift og doble mellomrom
    res = content.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ')
  
    # 2. Vask rundt matematiske operatorer
    res = res.gsub(/\s*([=><!]=?)\s*/, ' \1 ')
  
    # 3. Sørg for mellomrom rundt 'and' og 'or' KUN som hele ord
    # \b betyr "her starter/slutter et ord"
    # Vi legger på \s? for å håndtere hvis det allerede er et mellomrom eller en parentes
    res = res.gsub(/\b(and|or)\b/i, ' \1 ')
  
    # 4. Rydd opp i parenteser (fjern luft på innsiden, men behold luft på utsiden hvis det er en operator)
    res = res.gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
    
    # 5. Siden steg 3 og 4 kan ha laget doble mellomrom (f.eks. "  and  "), kjører vi en siste vask
    res = res.gsub(/\s+/, ' ').strip
  
    # 6. Spesialfiks for vanlige eForms-tilfeller som ble "vasket bort"
    res = res.gsub(/\)and\(/, ') and (')
    res = res.gsub(/\)or\(/, ') or (')
  
    res
  end

  # --- ID-GENERERING ---

  def self.alpha_index(n)
    s = +""
    while n >= 0
      s.prepend((n % 26 + 'A'.ord).chr)
      n = n / 26 - 1
    end
    s
  end

  def self.rule_id(domain:, scope:, kind:, sub_kind: nil, index:)
    # Vi henter gruppe-nummeret fra registeret. 
    # Vi sender med sub_kind slik at registeret kan differensiere f.eks. 'works' fra 'supplies'
    group_id = RuleIdRegistry.group(
      domain: domain, 
      scope: scope, 
      kind: kind, 
      sub_kind: sub_kind
    )
    format(
      "EFORMS-NOR-NATIONAL-%s-R%03d%s",
      domain,
      group_id,
      alpha_index(index)
    )
  end

  # --- XPATH-GENERATORER (LOGIKK) ---

  # Genererer XPath for konsistens-regler (kind: consistency)
  def self.build_consistency_xpath(logic, params, mapping)
    case logic.to_s
    when 'any_of'
      codes = params['codes'].map { |c| "'#{c}'" }.join(', ')
      
      parts = params['targets'].map do |t|
        m = mapping[t] || mapping[t.to_s] || raise("Ukjent target i mapping: #{t}")
        xpath_base = m['xpath']
        
        if t.to_s.start_with?('additional_')
          "(some $l in #{xpath_base} satisfies normalize-space($l) = (#{codes}))"
        else
          "normalize-space(#{xpath_base}) = (#{codes})"
        end
      end
      
      parts.join(" or ")
    else
      raise "Støtter foreløpig ikke logikk-typen: #{logic}"
    end
  end

  # Genererer flere regler basert på en felles kodeliste (kind: whitelist)
  # eu_codelist_path kommer nå fra Make via generate_fragments.rb
  def self.build_split_whitelist(params, base_path, eu_codelist_path, domain, mapping)
    # Finn fila i EU-mappa
    eu_list_path = Pathname.new(eu_codelist_path).join("#{params['base_list']}.yaml")
    
    unless eu_list_path.exist?
      raise "❌ Fant ikke EU-kodeliste: #{eu_list_path}"
    end

    # Laster koder (håndterer både Hash og Array fra YAML)
    data = YAML.load_file(eu_list_path)
    eu_codes = data.is_a?(Hash) ? data.keys : Array(data)
    
    # Slå sammen med nasjonale tillegg
    all_allowed = (eu_codes + Array(params['include'])).uniq.sort
    test_expr = "normalize-space() = (#{all_allowed.map { |c| "'#{c}'" }.join(', ')})"

    # Generer én regel per entry
    params['entries'].map.with_index do |entry, i|
      target_meta = mapping[entry['target']] || raise("Ukjent target i mapping: #{entry['target']}")
      
      {
        'field_id' => target_meta['field_id'],
        'id'        => rule_id(domain: domain, scope: entry['scope'], kind: :whitelist, index: i),
        'test'      => test_expr,
        'message'   => entry.dig('description', 'eng')
      }
    end
  end
                                                                                     
  def self.extract_message(params, meta, fallback: "Validation failed (no description provided)")
    # 1. Prøv spesifikk oversettelse i params
    msg = params.dig('_description', 'eng')
    
    # 2. Prøv generell beskrivelse i meta
    msg ||= meta['description']
    
    # 3. Bruk fallback hvis begge er nil/tomme
    msg = fallback if msg.nil? || msg.strip.empty?
    
    # Vask prosateksten før den returneres
    clean_prosa(msg)
  end
  
  # Hjelper for å hente koder, enten fra params eller fra en ekstern kodeliste
  def self.resolve_codes(params, eu_codelist_path)
    if params['base_list']
      path = Pathname.new(eu_codelist_path).join("#{params['base_list']}.yaml")
      raise "❌ Fant ikke kodeliste: #{path}" unless path.exist?
      
      data = YAML.load_file(path)
      all_codes = data.is_a?(Hash) ? data.keys : Array(data)

      if params['base_modification'] == 'leaves-only'
        # Sorterer etter lengde (lengst først) er ikke nødvendig, men vi sjekker prefix.
        # En kode er en "forelder" hvis det finnes en annen kode som starter med (kode + "-")
        codes = all_codes.reject do |code|
          all_codes.any? { |other| other.start_with?("#{code}-") }
        end
      else
        codes = all_codes
      end
      
      return (codes + Array(params['codes']) + Array(params['include'])).uniq.sort
    end

    Array(params['codes'] || params['code'])
  end
  
  # Eldre hvitliste-generator for flate lister
  def self.xpath_whitelist(values, indent: 8)
    padding = " " * indent
    formatted_values = values.map { |v| "#{padding}'#{v}'" }.join(",\n")
    "normalize-space() = (\n#{formatted_values}\n#{padding[0...-2]})"
  end

  # --- HJELPEMETODER ---

  def self.load_header(path, filename)
    File.read(path).gsub('<FRAGMENT_FILENAME>', filename)
  end
end
