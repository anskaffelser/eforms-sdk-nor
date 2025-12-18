#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

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

    res = content.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ')
    res = res.gsub(/\s*\/\s*/, '/')
             .gsub(/\s*\*\s*/, '*')
             .gsub(/\s*\(\s*/, '(')
             .gsub(/\s*\)\s*/, ')')

    res = res.gsub(/\s*<=\s*/, ' <= ')
             .gsub(/\s*>=\s*/, ' >= ')
             .gsub(/\s*!=\s*/, ' != ')
             .gsub(/\s*>\s*(?!=)/, ' > ')
             .gsub(/\s*<\s*(?!=)/, ' < ')
             .gsub(/(?<![<>!])\s*=\s*/, ' = ')

    res = res.gsub(/\)or\(/i, ') or (')
             .gsub(/\)or/i, ') or')
             .gsub(/or\(/i, ' or (')
             .gsub(/\)and\(/i, ') and (')
             .gsub(/\)and/i, ') and')
             .gsub(/and\(/i, ' and (')
             .gsub(/some\$/i, ' some $')
             .gsub(/\ssatisfies\s*/i, ' satisfies ')

    res = res.gsub(/('\s+)/, "'")
             .gsub(/(\s+')/, "'")
             .gsub(/='/, "= '")
             .gsub(/','/, "', '")

    res.strip
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

  def self.rule_id(domain:, scope:, kind:, index:)
    format(
      "EFORMS-NOR-NATIONAL-%s-R%03d%s",
      domain,
      RuleIdRegistry.group(domain: domain, scope: scope, kind: kind),
      alpha_index(index)
    )
  end

  # --- XPATH-GENERATORER (LOGIKK) ---

  # Genererer XPath for konsistens-regler (kind: consistency)
  # Bruker nå mapping-argument i stedet for hardkodet TARGET_MAP
  def self.build_consistency_xpath(logic, params, mapping)
    case logic.to_s
    when 'any_of'
      codes = params['codes'].map { |c| "'#{c}'" }.join(', ')
      
      parts = params['targets'].map do |t|
        m = mapping[t] || mapping[t.to_s] || raise("Ukjent target i mapping: #{t}")
        xpath_base = m['xpath']
        
        # Bruker 'some'-logikk hvis target indikerer en liste (additional_*)
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
  def self.build_split_whitelist(params, base_path, domain, mapping)
    # 1. Last kodeliste fra EU-mappa
    eu_list_path = base_path.join("src/codelists/#{params['base_list']}.yaml")
    eu_codes = YAML.load_file(eu_list_path).keys
    
    # 2. Slå sammen med nasjonale tillegg
    all_allowed = (eu_codes + Array(params['include'])).uniq.sort
    test_expr = "normalize-space() = (#{all_allowed.map { |c| "'#{c}'" }.join(', ')})"

    # 3. Generer én regel per entry i policy-fila
    params['entries'].map.with_index do |entry, i|
      target_meta = mapping[entry['target']] || raise("Ukjent target i mapping: #{entry['target']}")
      
      {
        'field_id' => target_meta['field_id'],
        'id'       => rule_id(domain: domain, scope: entry['scope'], kind: :whitelist, index: i),
        'test'     => test_expr,
        'message'  => entry.dig('description', 'eng')
      }
    end
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
