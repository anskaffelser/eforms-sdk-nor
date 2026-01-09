#!/usr/bin/env ruby
# frozen_string_literal: true

# =====================================================================
# Copyright © 2025 DFØ – The Norwegian Agency for Public and Financial
#                        Management
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or 
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =====================================================================

require 'yaml'
require 'pathname'
require 'optparse'
require_relative 'rule_id_registry'
require_relative 'national_rules_helpers'

# --- 1. ARGUMENT PARSING ---
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_fragments.rb [options]"

  opts.on("-i", "--input FILE", "Input YAML source") { |v| options[:input] = v }
  opts.on("-o", "--output FILE", "Output fragment destination") { |v| options[:output] = v }
  opts.on("-m", "--mapping FILE", "Path to eforms_fields_mapping.yaml") { |v| options[:mapping] = v }
  opts.on("-r", "--registry FILE", "Path to rule_id_registry.yaml") { |v| options[:registry] = v }
  opts.on("-l", "--license FILE", "Path to LICENSE_HEADER template") { |v| options[:license] = v }
  opts.on("-b", "--base DIR", "Base directory for national policy") { |v| options[:base] = v }
  opts.on("-e", "--eu-codelists DIR", "Path to EU standard codelists") { |v| options[:eu_codelists] = v }
  opts.on("-x", "--external-data DIR", "Path to external API data (CPV, etc)") { |v| options[:external_data]= v }
end.parse!

[:input, :output, :mapping, :registry, :license, :base, :eu_codelists, :external_data].each do |opt|
  abort "❌ Mangler påkrevd argument: --#{opt}" unless options[opt]
end

# --- 2. INITIALIZATION & DATA LOADING ---
begin
  RuleIdRegistry.load(options[:registry])
rescue => e
  abort "❌ Kunne ikke laste RuleIdRegistry: #{e.message}"
end

def load_input_data(path)
  return nil unless File.exist?(path)
  docs = YAML.load_stream(File.read(path))
  docs.find { |d| d && (d.key?('logic') || d.key?('params') || d.key?('base')) }
end

FIELD_MAPPING = YAML.load_file(options[:mapping])
input_file_path = File.expand_path(options[:input])
raw_data = load_input_data(input_file_path)
abort "❌ Fant ingen logikk i #{options[:input]}" unless raw_data

# --- 3. HANDLER ENGINE ---
module FragmentHandlers
  # 1. Mandatory Requirements (.fields.fragment.yaml)
  def self.mandatory_requirements(params, meta, mapping, base_dir, eu_dir, *)
    cond = params['condition']
    source_path = if cond['source']
                    Pathname.new(base_dir).join(cond['source'])
                  else
                    Pathname.new(base_dir).join(cond['source_folder'] || '', cond['source_file'])
                  end

    unless source_path.exist?
      abort "❌ Kilde-fil for mandatory_requirements finnes ikke: #{source_path}"
    end

    source_data = YAML.load_stream(File.read(source_path)).find { |d| d['logic'] == 'any_of' }
    codes = Array(source_data.dig('params', 'codes')).map { |c| c['type'] || c }

    result = {}
    params['fields'].each do |f|
      t_info = mapping[f['target']] || raise("Ukjent target: #{f['target']}")
      f_meta = meta.merge(f['_rule'] || {})
      
      result[t_info['field_id']] = {
        'xpath' => t_info['xpath'],
        'mandatory' => {
          'severity' => f_meta['severity'] || 'ERROR',
          'kind' => f_meta['kind'] || 'presence',
          'constraints' => [{ 'noticeTypes' => codes.dup }]
        }
      }
    end
    result
  end

  # 2. Any Of / Codelist Validation (.rules.fragment.yaml)
  def self.any_of(params, meta, mapping, _base_dir, eu_dir, *)
    targets = Array(params['targets'] || params['target'])
    raw_codes = NationalRulesHelpers.resolve_codes(params, eu_dir)
    clean_codes = raw_codes.map { |c| c.is_a?(Hash) ? c['type'] : c }
    formatted_codes = clean_codes.map { |c| "'#{c}'" }.join(', ')
    msg = NationalRulesHelpers.extract_message(params, meta)

    result = {}

    # --- LOGIKK FOR SPRÅK (LG) ---
    if meta['domain'] == 'LG' && (meta['kind'] == 'consistency' || targets.size > 1)
      # Henter index fra params hvis den finnes, ellers default 1
      t_index = params['index'] || 1

      id = NationalRulesHelpers.rule_id(
        domain: meta['domain'], 
        scope: meta['scope'] || 'global', 
        kind: meta['kind']&.to_sym || :consistency, 
        index: t_index
      )

      main_lang_xpath = mapping['main_notice_language']&.fetch('xpath') 
      additional_lang_xpath = mapping['additional_notice_language']&.fetch('xpath')

      xpath_test = <<~XPATH
        normalize-space(#{main_lang_xpath}) = (#{formatted_codes})
        or
        (some $l in #{additional_lang_xpath} satisfies normalize-space($l) = (#{formatted_codes}))
      XPATH

      result['ND-Root'] = [{
        'id' => id,
        'test' => xpath_test.gsub(/\s+/, ' ').strip,
        'message' => msg
      }]
      
    # --- LOGIKK FOR ANDRE FELT (CR, LB, osv.) ---
    else
      targets.each do |target_entry|
        is_hash = target_entry.is_a?(Hash)
        t_key   = is_hash ? target_entry['key']   : target_entry
        # Samme logikk for index her
        t_index = is_hash ? (target_entry['index'] || 1) : 1
        
        t_info = mapping[t_key] || raise("Ukjent target i mapping: #{t_key}")
        
        t_scope = if is_hash && target_entry['scope']
                    target_entry['scope']
                  else
                    t_info['scope'] || t_info['level'] || meta['scope'] || 'global'
                  end

        id = NationalRulesHelpers.rule_id(
          domain: meta['domain'], 
          scope: t_scope, 
          kind: meta['kind']&.to_sym || :whitelist, 
          index: t_index
        )

        attr_name = params['attribute']
        test_subject = attr_name ? "@#{attr_name}" : "."
        test = "normalize-space(#{test_subject}) = (#{formatted_codes})"

        result[t_info['field_id']] = [{
          'id' => id,
          'test' => NationalRulesHelpers.clean_xpath(test),
          'message' => msg
        }]
      end
    end
    result
  end

  # 3. Split Whitelist (.rules.fragment.yaml)
  def self.split_whitelist(params, meta, mapping, base_dir, eu_dir, *)
    # Merk: split_whitelist bruker ofte sine egne meldinger per entry, 
    # men vi kan bruke extract_message som fallback i hjelperen hvis ønskelig.
    raw_rules = NationalRulesHelpers.build_split_whitelist(params, Pathname.new(base_dir), Pathname.new(eu_dir), meta['domain'], mapping)

    result = {}
    raw_rules.each do |r|
      result[r['field_id']] ||= []
      result[r['field_id']] << {
        'id'      => r['id'],
        'test'    => NationalRulesHelpers.clean_xpath(r['test']),
        'message' => NationalRulesHelpers.clean_prosa(r['message'])
      }
    end
    result
  end

  # 4. Pattern Validation (.rules.fragment.yaml)
  def self.pattern(params, meta, mapping, _base_dir, eu_dir, *)
    # Støtt både 'target' (gammel) og 'targets' (ny liste)
    targets = Array(params['targets'] || params['target'] || raise("Mangler target(s) for pattern-regel"))
    pattern = params['pattern']
    msg     = NationalRulesHelpers.extract_message(params, meta)
    
    allow_blank = params['allow_blank']
    
    result = {}

    targets.each do |target_entry|
      # 1. Pakk ut nøkkel og indeks
      is_hash = target_entry.is_a?(Hash)
      t_key   = is_hash ? target_entry['key']   : target_entry
      t_index = is_hash ? (target_entry['index'] || 0) : 0
      
      t_info  = mapping[t_key] || raise("Ukjent target: #{t_key}")

      # 2. Finn scope (Target -> Meta -> Mapping -> Fallback)
      t_scope = if is_hash && target_entry['scope']
                  target_entry['scope']
                else
                  meta['scope'] || t_info['scope'] || t_info['level'] || 'global'
                end

      # 3. Generer ID med riktig indeks og scope
      id = NationalRulesHelpers.rule_id(
        domain: meta['domain'], 
        scope: t_scope, 
        kind: :pattern, 
        index: t_index
      )

      # 4. Bygg testen
      # Start med selve kjerne-testen
      test_parts = ["matches(normalize-space(.), '#{pattern}')"]

      # Legg til "blank-shaming" beskyttelse forrest i køen hvis det er tillatt
      test_parts.unshift("not(normalize-space(.))") if allow_blank
      
      test = test_parts.join(" or ")

      # 5. Legg til i resultatet (fletting skjer i assemble-skriptet)
      result[t_info['field_id']] = [{
        'id' => id,
        'test' => NationalRulesHelpers.clean_xpath(test),
        'message' => msg
      }]
    end
    result
  end
  
  # 5. National Tailored Codelist Pair (.rules.fragment.yaml)
  def self.national_tailored_codelist_pair(data, meta, mapping, _base_dir, eu_dir, *)
    result = {}
    definitions = data['definitions'] || {}
    entries = definitions['entries'] || []
    
    # 1. BT-01(e) - Enkel kodeliste-sjekk
    code_config = data['params']['entries'].find { |e| e['tailored_codelist_key'] == 'code' }
    code_field = mapping[code_config['target']]['field_id']
    code_list = entries.map { |e| "'#{e['code']}'" }.join(', ')
    
    result[code_field] = [{
      'id' => NationalRulesHelpers.rule_id(domain: meta['domain'], scope: code_config['scope'], kind: meta['kind'], index: 0),
      'test' => "normalize-space() = (#{code_list})",
      'message' => code_config['description']['eng']
    }]
  
    # 2. BT-01(f) - Betinget par-sjekk (Hvis kode X, så tekst Y)
    desc_config = data['params']['entries'].find { |e| e['scope'] == 'description' }
    desc_field = mapping[desc_config['target']]['field_id']
  
    # Vi bygger én stor sjekk som validerer teksten basert på koden i nabofeltet
    conditional_checks = entries.map do |e|
      txt_nob = NationalRulesHelpers.generate_legal_label(e, definitions, desc_config['templates'], 'nob')
      txt_eng = NationalRulesHelpers.generate_legal_label(e, definitions, desc_config['templates'], 'eng')
  
      # Logikk: Hvis ../cbc:ID er 'KODE', så må dette feltet være riktig tekst på riktig språk
      "(normalize-space(../cbc:ID) = '#{e['code']}' and (
          (@languageID = 'NOR' and normalize-space() = '#{txt_nob}') or 
          (@languageID = 'ENG' and normalize-space() = '#{txt_eng}')
      ))"
    end

    raw_test = conditional_checks.join(' or ')

    msg = desc_config['description']['eng']
  
    result[desc_field] = [{
      'id' => NationalRulesHelpers.rule_id(domain: meta['domain'], scope: desc_config['scope'], kind: meta['kind'], index: 1),
      'test' => NationalRulesHelpers.clean_xpath(raw_test),
      'message' => msg
    }]
  
    result
  end

  # 6. Sum av verdier på tvers av felter
  def self.cross_field_sum(params, meta, mapping, _base_dir, eu_dir, *)
    relations = Array(params['relations'] || [])
    tolerance = params['tolerance'] || 0.01
    result    = {}
  
    relations.each do |rel|
      p_key  = rel['parent_key']
      p_info = mapping[p_key] || raise("Ukjent parent_key: #{p_key}")
      parent_xpath = p_info['xpath']
      
      # Henter spesifikk melding for denne relasjonen
      msg = NationalRulesHelpers.extract_message(rel, meta)
      
      parent_rules = []
  
      Array(rel['child_keys']).each do |child_entry|
        c_key = child_entry['key']
        c_idx = child_entry['index'] || 1
        c_info = mapping[c_key] || raise("Ukjent child_key: #{c_key}")
        child_xpath = c_info['xpath']
  
        id = NationalRulesHelpers.rule_id(
          domain: meta['domain'],
          scope: meta['scope'],
          kind: :comparison,
          index: c_idx
        )
  
        # XPath-logikk: (Hvis barnet ikke finnes) ELLER (Differansen er OK)
        test = "(not(#{child_xpath})) or abs(number(#{parent_xpath}) - sum(#{child_xpath})) < #{tolerance}"
  
        parent_rules << {
          'id' => id,
          'test' => NationalRulesHelpers.clean_xpath(test),
          'message' => msg
        }
      end
  
      result[p_info['field_id']] ||= []
      result[p_info['field_id']].concat(parent_rules)
    end
  
    result
  end
  
  # 7. Likhet på tvers av felter
  def self.cross_field_equality(params, meta, mapping, *)
    entries = Array(params['entries'] || [])
    result = {}
  
    entries.each_with_index do |entry, idx|
      # Henter info basert på nøkkelen i denne spesifikke entryen
      key = entry['key']
      info = mapping[key] || raise("Ukjent key i cross_field_equality: #{key}")
      full_path = info['xpath']
      
      # Henter meldingen som ligger lokalt i denne entryen
      msg = NationalRulesHelpers.extract_message(entry, meta)
  
      # XPath-testen forblir den samme robuste sjekken mot første forekomst
      test = "normalize-space() = #{full_path}[1]/normalize-space()"
  
      # Grupperer regelen under riktig field_id (BT-536, BT-537, etc)
      id = NationalRulesHelpers.rule_id(
        domain: meta['domain'],
        scope: entry['scope'] || meta['scope'],
        kind: meta['kind'],
        index: idx
      )
      result[info['field_id']] ||= []
      result[info['field_id']] << {
        'id' => id,
        'test' => test,
        'message' => msg
      }
    end
  
    result
  end

  # 8. Dato-nærhet (BT-05(a)-Notice# 8. Dato-nærhet (BT-05 Dispatch Date)
  def self.date_proximity(params, meta, mapping, *)
    # Vi antar params['key'] peker på BT-05(a)-notice i din mapping
    info = mapping[params['key']] || raise("Ukjent key i date_proximity: #{params['key']}")
    
    # Henter grenser fra YAML, f.eks. -1 (i går) og 2 (i overmorgen)
    min = params['min_days'] || -1
    max = params['max_days'] || 2
    
    msg = NationalRulesHelpers.extract_message(params, meta)
    
    # Helper for å formatere duration: -1 blir -P1D, 2 blir P2D
    to_duration = ->(days) {
      prefix = days < 0 ? "-P" : "P"
      "#{prefix}#{days.abs}D"
    }

    min_dur = to_duration.call(min)
    max_dur = to_duration.call(max)

    # XPath-logikk:
    # current-date() returnerer dagens dato. 
    # Vi trekker fra datoen i feltet og sjekker om varigheten (duration) 
    # er innenfor de tillatte grensene.
    test = "((current-date() - xs:date(.)) le xs:dayTimeDuration('#{max_dur}')) and " \
           "((current-date() - xs:date(.)) ge xs:dayTimeDuration('#{min_dur}'))"

    id = NationalRulesHelpers.rule_id(
      domain: meta['domain'],
      kind:   meta['kind'],
      scope:  params['scope'] || meta['scope'],
      index:  params['index'] || 1
    )

    {
      info['field_id'] => [{
        'id' => id,
        'test' => NationalRulesHelpers.clean_xpath(test),
        'message' => msg
      }]
    }
  end
  
  # 9. Forbudte elementer (f.eks. uoffisielle språk)
  def self.forbidden_element(params, meta, mapping, *)
    info = mapping[params['key']] || raise("Ukjent key: #{params['key']}")
    xpath = info['xpath']
    msg = NationalRulesHelpers.extract_message(params, meta)

    # XPath-testen: Det skal IKKE finnes noen forekomster av denne stien
    test = "not(#{xpath})"

    id = NationalRulesHelpers.rule_id(
      domain: meta['domain'],
      kind:   meta['kind'],
      scope:  params['scope'] || meta['scope'],
      index:  params['index'] || 1
    )

    # Vi returnerer dette under 'ND-Root' fordi det er en strukturell sjekk
    {
      "ND-Root" => [{
        'id' => id,
        'test' => NationalRulesHelpers.clean_xpath(test),
        'message' => msg
      }]
    }
  end
  
  # 10. Terskelverdi-motor
  def self.threshold_engine(params, meta, mapping, base_dir, eu_dir, external_data_dir)
    result = {}
    deps = params['_dependencies']
    abort "❌ Mangler '_dependencies' i YAML" if deps.nil?
    @cpv_cache ||= {} # Cache for å unngå disk-I/O i loopen
    
    # Finn stier
    v_path  = mapping.dig(deps['fields']['value'], 'xpath')
    b_path  = mapping.dig(deps['fields']['legal_basis'], 'xpath')
    bd_path = mapping.dig(deps['fields']['legal_basis_description_nor'], 'xpath')
    t_path  = mapping.dig(deps['fields']['buyer_legal_type'], 'xpath')
    cn_path = mapping.dig(deps['fields']['contract_nature_main_proc'], 'xpath')
    cp_path = mapping.dig(deps['fields']['main_cpv_proc'], 'xpath')
    
    target_field_id = mapping.dig(deps['fields']['value'], 'field_id')

    # Last register for lovhjemler
    lb_file = deps['external_data'].find { |d| d['id'] == 'lb_registry' }['file']
    lb_data = YAML.load_file(File.join(base_dir, lb_file))
    lb_entries      = lb_data['definitions']['entries']
    lb_definitions = lb_data['definitions']
    lb_templates   = lb_data['params']['entries'].find { |e| e['scope'] == 'description' }['templates']

    params['rules'].each do |rule|
      current_domain = rule['id_path'].first
      
      matching_entry = lb_entries.find do |e| 
        e['threshold_scope'] == rule['context']['lb_scope'] && 
        e['regulation'] == current_domain
      end
      raise "Fant ikke LB for #{current_domain} / #{rule['context']['lb_scope']}" unless matching_entry
      
      expected_text = NationalRulesHelpers.generate_legal_label(matching_entry, lb_definitions, lb_templates, 'nob')

      conditions = []
      
      # 1. Lovhjemmel (LB-klausul)
      lb_check = "normalize-space(#{b_path}) = '#{matching_entry['code'].strip}'"
      if bd_path && expected_text
        lb_check += " and normalize-space(#{bd_path}) = '#{expected_text.gsub("'", "&apos;")}'"
      end
      conditions << "(#{lb_check})"

      # 2. Buyer type filter (CGA / Non-CGA)
      lt_filter = rule['context']['lt_filter']
      if lt_filter && lt_filter != "any"
        case lt_filter
        when /^contains:(.+)/ then conditions << "contains(normalize-space(#{t_path}), '#{$1}')"
        when /^not_contains:(.+)/ then conditions << "not(contains(normalize-space(#{t_path}), '#{$1}'))"
        end
      end

      # 3. Kontraktens art (Nature) og CPV-inkludering
      type_or_cpv = []
      
      # Håndter Nature (støtter streng eller liste)
      if rule['context']['nature'] && cn_path
        natures = Array(rule['context']['nature'])
        nature_checks = natures.map { |n| "normalize-space(#{cn_path})='#{n}'" }
        type_or_cpv << (nature_checks.size > 1 ? "(#{nature_checks.join(' or ')})" : nature_checks.first)
      end

      # Håndter positiv CPV-inkludering
      if rule['cpv_import'] && cp_path
        imp = rule['cpv_import']
        cpv_file_path = File.join(external_data_dir, imp['file'])
        
        unless File.exist?(cpv_file_path)
          abort "❌ CPV-fil ikke funnet: #{cpv_file_path}"
        end

        @cpv_cache[cpv_file_path] ||= YAML.load_file(cpv_file_path)
        cpv_data = @cpv_cache[cpv_file_path][imp['key']]
        
        if cpv_data
          build_clause = ->(code, is_not = false) {
            c_str = code.to_s
            xpath_func = c_str.length == 8 ? "normalize-space(#{cp_path})='#{c_str}'" : "starts-with(normalize-space(#{cp_path}), '#{c_str}')"
            is_not ? "not(#{xpath_func})" : xpath_func
          }

          inc_list = Array(cpv_data['include']).map { |c| build_clause.call(c) }
          exc_list = Array(cpv_data['exclude']).map { |c| build_clause.call(c, true) }

          if inc_list.any?
            type_or_cpv << (exc_list.any? ? "((#{inc_list.join(' or ')}) and #{exc_list.join(' and ')})" : "(#{inc_list.join(' or ')})")
          end
        end
      end

      # Legg til samlet Nature/CPV-inkludering i hovedbetingelsene
      if type_or_cpv.any?
        conditions << "(#{type_or_cpv.join(' or ')})"
      end

      # 4. CPV-ekskludering (Negasjon av andre kategorier)
      if rule['exclude_cpv_import'] && cp_path
        Array(rule['exclude_cpv_import']).each do |imp|
          cpv_file_path = File.join(external_data_dir, imp['file'])
          next unless File.exist?(cpv_file_path)

          @cpv_cache[cpv_file_path] ||= YAML.load_file(cpv_file_path)
          cpv_data = @cpv_cache[cpv_file_path][imp['key']]
          next unless cpv_data

          # Vi ekskluderer alt som er definert i 'include' for den gitte nøkkelen
          Array(cpv_data['include']).each do |code|
            c_str = code.to_s
            if c_str.length == 8
              conditions << "not(normalize-space(#{cp_path})='#{c_str}')"
            else
              conditions << "not(starts-with(normalize-space(#{cp_path}), '#{c_str}'))"
            end
          end
        end
      end

      # 5. Bygg endelig XPath-test
      clean_test_expr = rule['test'].gsub(/(\d)_(\d)/, '\1\2') # Håndter 7_800_000 -> 7800000
      xpath_test = clean_test_expr.gsub('value', "number(#{v_path})")

      full_xpath = "if (#{conditions.join(' and ')}) then (#{xpath_test}) else true()"

      reg_num = RuleIdRegistry.dig_id("TH", *rule['id_path'])
      rule_id = "EFORMS-NOR-NATIONAL-TH-R#{reg_num.to_s.rjust(3, '0')}"

      result[target_field_id] ||= []
      result[target_field_id] << {
        'id' => rule_id,
        'test' => NationalRulesHelpers.clean_xpath(full_xpath),
        'message' => NationalRulesHelpers.extract_message(rule, meta)
      }
    end
    result
  end


end

# --- 4. EXECUTION ---
logic_type = raw_data['logic']
meta = raw_data['_rule'] || {}

if logic_type == 'national_tailored_codelist_pair'
  payload = raw_data
else
  payload = raw_data['params'] || {}
end

if FragmentHandlers.respond_to?(logic_type)
  result_hash = FragmentHandlers.send(logic_type, payload, meta, FIELD_MAPPING, options[:base], options[:eu_codelists], options[:external_data])
else
  abort "❌ Ukjent logikk-type: #{logic_type}"
end

# --- 5. OUTPUT ---
if result_hash && !result_hash.empty?
  output_path = Pathname.new(options[:output])
  output_path.dirname.mkpath
  header = NationalRulesHelpers.load_header(options[:license], output_path.basename.to_s)
  File.write(output_path, header + result_hash.to_yaml(line_width: -1))
  puts "✅ Generated: #{output_path.basename}"
else
  abort "❌ Ingen data produsert for #{options[:input]}"
end
