#!/usr/bin/env ruby
# frozen_string_literal: true

# =====================================================================
# Copyright © 2025 DFØ – The Norwegian Agency for Public and Financial
#                     Management
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
  opts.on("-n", "--nor-codelists DIR", "Path to NO extension codelists") { |v| options[:no_codelists] = v }
  opts.on("-x", "--external-data DIR", "Path to external API data (CPV, etc)") { |v| options[:external_data]= v }
end.parse!

# Sjekk at alle påkrevde stier er med fra Makefile
[:input, :output, :mapping, :registry, :license, :base, :eu_codelists, :no_codelists, :external_data].each do |opt|
  abort "❌ Mangler påkrevd argument: --#{opt.to_s.gsub('_', '-')}" unless options[opt]
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
  def self.mandatory_requirements(params, meta, context)
    mapping = context[:mapping]
    cond = params['condition']
    source_path = if cond['source']
                    Pathname.new(context[:base]).join(cond['source'])
                  else
                    Pathname.new(context[:base]).join(cond['source_folder'] || '', cond['source_file'])
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
  def self.any_of(params, meta, context)
    mapping = context[:mapping]
    targets = Array(params['targets'] || params['target'])
    raw_codes = NationalRulesHelpers.resolve_codes(params, context[:eu_codelists])
    clean_codes = raw_codes.map { |c| c.is_a?(Hash) ? c['type'] : c }
    formatted_codes = clean_codes.map { |c| "'#{c}'" }.join(', ')
    msg = NationalRulesHelpers.extract_message(params, meta)
    
    is_mandatory = params['mandatory'] == true

    result = {}

    # Hvis 'collective' er true, vil vi ha EN test for ALLE targets
    # Hvis ikke, kjører vi den gamle loopen som før.
    if params['collective']
      # Vi grupperer fremdeles etter context_node for å unngå XPath-kræsj
      grouped = targets.group_by do |t|
        is_h = t.is_a?(Hash)
        t_key = is_h ? t['key'] : t
        t_info = mapping[t_key] || raise("Ukjent target: #{t_key}")
        (is_h && t['context_node']) || params['context_node'] || t_info['field_id']
      end

      grouped.each do |context_node, entries|
        subjects = entries.map do |e|
          is_h = e.is_a?(Hash)
          t_info = mapping[is_h ? e['key'] : e]
          subject = (context_node == 'ND-Root') ? t_info['xpath'] : "."
          params['attribute'] ? "#{subject}/@#{params['attribute']}" : subject
        end

        # Samlet test: (Path1, Path2) = ('NOR', 'NOB')
        test = "(#{subjects.join(', ')}) = (#{formatted_codes})"
        
        value_check = clean_codes.any? ? "(#{subjects.join(', ')}) = (#{formatted_codes})" : nil

        if is_mandatory
          existence_check = subjects.map { |s| "string-length(normalize-space(#{s})) > 0"}.join(' or ')
          test = value_check ? "((#{existence_check}) and #{value_check})" : "(#{existence_check})"
        else
          test = value_check || "true()"
        end
        
        test = apply_legal_basis_noid_exemption(test, params, mapping, context)
        
        # Bruker info fra første target for ID
        first = entries.first
        id = NationalRulesHelpers.rule_id(
          domain: meta['domain'], 
          scope: (first.is_a?(Hash) && first['scope']) || params['scope'] || 'global',
          kind: meta['kind']&.to_sym || :whitelist,
          index: (first.is_a?(Hash) ? first['index'] : params['index']) || 1
        )

        result[context_node] ||= []
        result[context_node] << { 'id' => id, 'test' => NationalRulesHelpers.clean_xpath(test), 'message' => msg }
      end
    else
      # --- ORIGINAL LOGIKK (Uendret) ---
      targets.each_with_index do |target_entry, idx|
        is_hash = target_entry.is_a?(Hash)
        t_key   = is_hash ? target_entry['key'] : target_entry
        t_info  = mapping[t_key] || raise("Ukjent target i mapping: #{t_key}")
        
        context_node = (is_hash && target_entry['context_node']) || params['context_node'] || t_info['field_id']
        subject = (context_node == 'ND-Root') ? t_info['xpath'] : "."
        test_subject = params['attribute'] ? "#{subject}/@#{params['attribute']}" : subject

        id = NationalRulesHelpers.rule_id(
          domain: meta['domain'], 
          scope: (is_hash && target_entry['scope']) || params['scope'] || t_info['scope'] || 'global',
          kind: meta['kind']&.to_sym || :whitelist, 
          index: (is_hash ? target_entry['index'] : params['index']) || (idx + 1)
        )

        test = "normalize-space(#{test_subject}) = (#{formatted_codes})"

        value_check = clean_codes.any? ? "normalize-space(#{test_subject}) = (#{formatted_codes})" : nil

        if is_mandatory
          existence_check = "string-length(normalize-space(#{test_subject})) > 0"
          test = value_check ? "(#{existence_check}) and (#{test})" : existence_check
        else
          test = value_check || "true()"
        end
        
        test = apply_legal_basis_noid_exemption(test, params, mapping, context)

        result[context_node] ||= []
        result[context_node] << { 'id' => id, 'test' => NationalRulesHelpers.clean_xpath(test), 'message' => msg }
      end
    end
    result
  end
  

  # 3. Split Whitelist (.rules.fragment.yaml)
  def self.split_whitelist(params, meta, context)
    raw_rules = NationalRulesHelpers.build_split_whitelist(params, Pathname.new(context[:base]), Pathname.new(context[:eu_codelists]), meta['domain'], context[:mapping])
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
  def self.pattern(params, meta, context)
    mapping = context[:mapping]
    targets = Array(params['targets'] || params['target'] || raise("Mangler target(s) for pattern-regel"))
    pattern = params['pattern']
    msg     = NationalRulesHelpers.extract_message(params, meta)
    allow_blank = params['allow_blank']
    
    result = {}
    targets.each do |target_entry|
      is_hash = target_entry.is_a?(Hash)
      t_key   = is_hash ? target_entry['key']   : target_entry
      t_index = is_hash ? (target_entry['index'] || 0) : 0
      t_info  = mapping[t_key] || raise("Ukjent target: #{t_key}")
      t_scope = is_hash && target_entry['scope'] ? target_entry['scope'] : (meta['scope'] || t_info['scope'] || t_info['level'] || 'global')

      id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: t_scope, kind: :pattern, index: t_index)
      test_parts = ["matches(normalize-space(.), '#{pattern}')"]
      test_parts.unshift("not(normalize-space(.))") if allow_blank
      
      result[t_info['field_id']] = [{ 'id' => id, 'test' => NationalRulesHelpers.clean_xpath(test_parts.join(" or ")), 'message' => msg }]
    end
    result
  end
  
  # 5. National Tailored Codelist Pair (.rules.fragment.yaml)
  def self.national_tailored_codelist_pair(data, meta, context)
    mapping = context[:mapping]
    result = {}
    codelist_entries = data.dig('definitions', 'entries') || []
  
    data['params']['entries'].each_with_index do |config, idx|
      t_info = mapping[config['target']] || next
      context_node = config['context_node'] || t_info['field_id']
      subject = (context_node == 'ND-Root') ? t_info['xpath'] : "."
      
      id = NationalRulesHelpers.rule_id(
        domain: meta['domain'], 
        scope: config['scope'] || meta['scope'], 
        kind: meta['kind'], 
        index: idx
      )
  
      test = if config['type'] == 'literal'
               "normalize-space(#{subject}) = '#{config['value']}'"
             elsif config['type'] == 'enum'
               target_lang = config['lang'] || 'nor'
               
               # Henter alle unike koder for aktuelt språk
               clean_codes = codelist_entries.map { |e| e.dig('code', target_lang)&.strip }.compact.uniq
               
               # Formaterer til en XPath 2.0 sekvens: ('verdi1', 'verdi2', ...)
               formatted_codes = clean_codes.map { |c| "'#{c.gsub("'", "&apos;")}'" }.join(', ')
               
               subject_norm = "normalize-space(#{subject})"
               
               # LOGIKK: 
               # 1. Feltet finnes ikke (not(node))
               # 2. Feltet er tomt (norm = '')
               # 3. Feltet matcher en verdi i sekvensen (norm = (seq))
               "(not(#{subject}) or #{subject_norm} = (#{formatted_codes}))"
             end
  
      result[context_node] ||= []
      result[context_node] << {
        'id' => id,
        'test' => NationalRulesHelpers.clean_xpath(test),
        'message' => config['_description']['eng']
      }
    end
    result
  end

  # 6. Sum av verdier på tvers av felter
  def self.cross_field_sum(params, meta, context)
    mapping = context[:mapping]
    relations = Array(params['relations'] || [])
    tolerance = params['tolerance'] || 0.01
    result    = {}
  
    relations.each do |rel|
      p_info = mapping[rel['parent_key']] || raise("Ukjent parent_key: #{rel['parent_key']}")
      msg = NationalRulesHelpers.extract_message(rel, meta)
      
      parent_rules = []
      Array(rel['child_keys']).each do |child_entry|
        c_info = mapping[child_entry['key']] || raise("Ukjent child_key: #{child_entry['key']}")
        id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: meta['scope'], kind: :comparison, index: child_entry['index'] || 1)
        test = "(not(#{c_info['xpath']})) or abs(number(#{p_info['xpath']}) - sum(#{c_info['xpath']})) < #{tolerance}"
  
        parent_rules << { 'id' => id, 'test' => NationalRulesHelpers.clean_xpath(test), 'message' => msg }
      end
  
      result[p_info['field_id']] ||= []
      result[p_info['field_id']].concat(parent_rules)
    end
    result
  end
  
  # 7. Likhet på tvers av felter
  def self.cross_field_equality(params, meta, context)
    mapping = context[:mapping]
    entries = Array(params['entries'] || [])
    result = {}
  
    entries.each_with_index do |entry, idx|
      info = mapping[entry['key']] || raise("Ukjent key i cross_field_equality: #{entry['key']}")
      msg = NationalRulesHelpers.extract_message(entry, meta)
      id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: entry['scope'] || meta['scope'], kind: meta['kind'], index: idx)
      
      result[info['field_id']] ||= []
      result[info['field_id']] << { 'id' => id, 'test' => "normalize-space() = #{info['xpath']}[1]/normalize-space()", 'message' => msg }
    end
    result
  end

  # 8. Dato-nærhet
  def self.date_proximity(params, meta, context)
    info = context[:mapping][params['key']] || raise("Ukjent key i date_proximity: #{params['key']}")
    min = params['min_days'] || -1
    max = params['max_days'] || 2
    msg = NationalRulesHelpers.extract_message(params, meta)
    
    to_duration = ->(days) { "#{days < 0 ? "-P" : "P"}#{days.abs}D" }
    test = "((current-date() - xs:date(.)) le xs:dayTimeDuration('#{to_duration.call(max)}')) and ((current-date() - xs:date(.)) ge xs:dayTimeDuration('#{to_duration.call(min)}'))"

    id = NationalRulesHelpers.rule_id(domain: meta['domain'], kind: meta['kind'], scope: params['scope'] || meta['scope'], index: params['index'] || 1)

    { info['field_id'] => [{ 'id' => id, 'test' => NationalRulesHelpers.clean_xpath(test), 'message' => msg }] }
  end
  
  # 9. Forbudte elementer
  def self.forbidden_element(params, meta, context)
    info = context[:mapping][params['key']] || raise("Ukjent key: #{params['key']}")
    msg = NationalRulesHelpers.extract_message(params, meta)
    id = NationalRulesHelpers.rule_id(domain: meta['domain'], kind: meta['kind'], scope: params['scope'] || meta['scope'], index: params['index'] || 1)

    { "ND-Root" => [{ 'id' => id, 'test' => "not(#{info['xpath']})", 'message' => msg }] }
  end
  
  # 10. Terskelverdi-motor
  def self.threshold_engine(params, meta, context)
    mapping = context[:mapping]
    result = {}
    deps = params['_dependencies']
    
    raise "❌ Kritisk feil: Mangler '_dependencies'" if deps.nil?
    
    @cpv_cache ||= {}
    
    # --- 1. HENT FELTPERSTIER ---
    v_path  = mapping.dig(deps['fields']['value'], 'xpath')
    b_path  = mapping.dig(deps['fields']['legal_basis'], 'xpath')
    t_path  = mapping.dig(deps['fields']['buyer_legal_type'], 'xpath')
    cn_path = mapping.dig(deps['fields']['contract_nature_main_proc'], 'xpath')
    cp_path = mapping.dig(deps['fields']['main_cpv_proc'], 'xpath')
    target_field_id = mapping.dig(deps['fields']['value'], 'field_id')
  
    # FIKS 1: Sjekk at mapping faktisk returnerer noe her
    lb_desc_configs = Array(deps['fields']['legal_basis_descriptions']).map do |d|
      path = mapping.dig(d['legal_basis_description'], 'xpath')
      {
        xpath: path,
        lang: d['lang'] # Sjekk om denne er "NOR" eller "nor"
      }
    end.select { |c| c[:xpath] }
  
    # --- 2. LAST EKSTERNE DATA ---
    lb_registry_cfg = deps['external_data']&.find { |d| d['id'] == 'lb_registry' }
    lb_data = YAML.load_file(File.join(context[:base], lb_registry_cfg['file']))
    lb_entries = lb_data['definitions']['entries']
  
    # --- 3. PROSESSER HVER REGEL ---
    params['rules'].each do |rule|
      id = NationalRulesHelpers.rule_id(
        domain:   rule['domain']   || meta['domain'], 
        kind:     rule['kind']     || meta['kind'], 
        sub_kind: rule['sub_kind'], 
        scope:    rule['scope']    || meta['scope'], 
        index:    rule['index']    || 0
      )
  
      matching_entry = lb_entries.find do |e| 
        e['threshold_scope'] == rule['context']['lb_scope'] && e['regulation'] == (rule['scope'] || meta['domain']) 
      end
      
      next unless matching_entry
  
      conditions = []
      
      # Krav: BT-01(e)
      conditions << "(normalize-space(#{b_path}) = 'LocalLegalBasis')"
  
      # --- FIKS 2: Robust språksjekk ---
      language_ors = []
      lb_desc_configs.each do |cfg|
        # Vi tvinger både nøkkel og config til lowercase for å matche "NOR" mot "nor"
        lang_key = cfg[:lang].to_s.downcase
        expected_val = matching_entry.dig('code', lang_key) || matching_entry.dig('code', cfg[:lang].to_s)
        
        if expected_val
          safe_val = expected_val.strip.gsub("'", "&apos;")
          xpath_node = cfg[:xpath]
          language_ors << "(not(#{xpath_node}) or normalize-space(#{xpath_node}) = '#{safe_val}')"
        end
      end
      
      # Her dytter vi språksjekken inn i hovedlisten over betingelser
      if language_ors.any?
        conditions << "(#{language_ors.join(' and ')})"
      end
  
      # --- 4. ØVRIGE FILTRE ---
      lt_filter = rule['context']['lt_filter']
      if lt_filter && lt_filter != "any"
        case lt_filter
        when /^contains:(.+)/ then conditions << "contains(normalize-space(#{t_path}), '#{$1}')"
        when /^not_contains:(.+)/ then conditions << "not(contains(normalize-space(#{t_path}), '#{$1}'))"
        end
      end
  
      type_or_cpv = []
      if rule['context']['nature'] && cn_path
        nature_list = Array(rule['context']['nature']).map { |n| "'#{n}'" }.join(', ')
        # XPath 2.0 kompatibel sjekk
        type_or_cpv << "normalize-space(#{cn_path}) = (#{nature_list})"
      end
  
      if rule['cpv_import'] && cp_path
        imp = rule['cpv_import']
        cpv_data = @cpv_cache[File.join(context[:external_data], imp['file'])] ||= YAML.load_file(File.join(context[:external_data], imp['file']))
        cpv_list = cpv_data[imp['key']]
        if cpv_list
          # Bruker den stabile include-metoden
          inc_checks = Array(cpv_list['include']).map do |c|
            code = c.to_s
            code.length == 8 ? "normalize-space(#{cp_path})='#{code}'" : "starts-with(normalize-space(#{cp_path}), '#{code}')"
          end
          
          inc_clause = "(#{inc_checks.join(' or ')})"
          
          if Array(cpv_list['exclude']).any?
            exc_checks = Array(cpv_list['exclude']).map do |c|
              code = c.to_s
              code.length == 8 ? "not(normalize-space(#{cp_path})='#{code}')" : "not(starts-with(normalize-space(#{cp_path}), '#{code}'))"
            end
            type_or_cpv << "(#{inc_clause} and #{exc_checks.join(' and ')})"
          else
            type_or_cpv << inc_clause
          end
        end
      end
  
      conditions << "(#{type_or_cpv.join(' or ')})" if type_or_cpv.any?
  
      # --- 5. GENERER SLUTT-XPATH ---
      clean_test = rule['test'].gsub(/(\d)_(\d)/, '\1\2').gsub('value', "number(#{v_path})")
      final_xpath = "if (#{conditions.join(' and ')}) then (#{clean_test}) else true()"
  
      result[target_field_id] ||= []
      result[target_field_id] << {
        'id'      => id,
        'test'    => NationalRulesHelpers.clean_xpath(final_xpath),
        'message' => NationalRulesHelpers.extract_message(rule, meta)
      }
    end
    result
  end
  
  # 11: Nasjonale kodelister
  def self.national_codelist_dependency(params, meta, context)
    mapping = context[:mapping]
    result = {}
    deps = params['_dependencies']
    
    raise "❌ Kritisk feil: Mangler '_dependencies'" if deps.nil?
    
    # --- 1. HENT FELTPERSTIER ---
    target_key = params['target']
    target_info = mapping[target_key] || raise("Mapping mangler for target: #{target_key}")
    target_xpath = target_info['xpath']
    
    b_path = mapping.dig(deps['fields']['legal_basis_noid'], 'xpath')
    lb_desc_configs = Array(deps['fields']['legal_basis_descriptions']).map do |d|
      { xpath: mapping.dig(d['legal_basis_description'], 'xpath'), lang: d['lang'] }
    end.select { |c| c[:xpath] }

    # --- 2. HÅNDTER RELATIVITET ---
    is_relative = params['check_scope'] == 'relative'
    subject = is_relative ? "." : target_xpath
    element_name = target_xpath.split('/').last

    # --- 3. LAST EKSTERNE DATA ---
    lb_registry_cfg = deps['external_data']&.find { |d| d['id'] == 'lb_registry' }
    lb_data = YAML.load_file(File.join(context[:base], lb_registry_cfg['file']))
    lb_entries = lb_data['definitions']['entries']

    # --- 4. LAST KODELISTE-DATA (OPPDATERT) ---
    cl_path = File.join(context[:no_codelists], params['codelist_file'])
    cl_data = YAML.load_file(cl_path)
    cum_codes = cl_data['codes'].select { |c| c['validation_type'] == 'cumulative' }.map { |c| "'#{c['code']}'" }.join(', ')
    exc_codes = cl_data['codes'].select { |c| c['validation_type'] == 'exclusive' }.map { |c| "'#{c['code']}'" }.join(', ')

    # Denne logikken sjekker gjensidig utelukkelse (Brukes nå kun i 'count' og 'exclusivity')
    strict_logic = <<~XPATH.strip
      if (some $c in #{subject} satisfies normalize-space($c) = (#{exc_codes})) 
      then (not(some $c in #{subject} satisfies normalize-space($c) = (#{cum_codes})))
      else (some $c in #{subject} satisfies normalize-space($c) = (#{cum_codes}))
    XPATH

    # --- 5. PROSESSER REGLER ---
    params['rules'].each_with_index do |rule, idx|
      conditions = []
      
      if rule['regulation'] != 'ANY'
        matching_entry = lb_entries.find { |e| e['threshold_scope'] == rule['context']['lb_scope'] && e['regulation'] == rule['regulation'] }
        if matching_entry
          conditions << "(normalize-space(#{b_path}) = 'LocalLegalBasis')"
          language_ors = lb_desc_configs.map do |cfg|
            expected_val = matching_entry.dig('code', cfg[:lang].to_s.downcase)
            "(not(#{cfg[:xpath]}) or normalize-space(#{cfg[:xpath]}) = '#{expected_val.gsub("'", "&apos;")}')" if expected_val
          end.compact
          conditions << "(#{language_ors.join(' and ')})" if language_ors.any?
        end
      else
        conditions << "exists(#{b_path})"
      end
      
      # --- 6. GENERER TEST ---
      raw_test = rule['test']
      
      full_parts = target_xpath.split('/').reject(&:empty?)
      p_elem = params['parent_elem']
      p_idx = full_parts.index { |p| p.start_with?(p_elem) }
      
      if p_idx && is_relative
        steps = (full_parts.size - 1) - p_idx
        prefix = ([".."] * steps).join("/")
        sub = full_parts[p_idx + 1..-1].map { |p| p.gsub(/\[@listName=.*?\]/, '') }.join('/')
        sibling_path = "#{prefix}/#{sub}[@listName = '#{params['list_name']}']"
      else
        sibling_path = is_relative ? "../#{element_name}[@listName = '#{params['list_name']}']" : target_xpath
      end

      clean_test = case raw_test
                   when "always"
                     "((some $c in #{sibling_path} satisfies normalize-space($c) = (#{exc_codes}, #{cum_codes})))"
                     
                   when "exclusivity"
                     "(not((some $c in #{sibling_path} satisfies normalize-space($c) = (#{exc_codes})) and (some $c in #{sibling_path} satisfies normalize-space($c) = (#{cum_codes}))))"
                     
                   when /count/
                     presence_logic = "((some $c in #{sibling_path} satisfies normalize-space($c) = (#{exc_codes}, #{cum_codes})))"
                     actual_condition = raw_test.gsub("count", "count(#{sibling_path})")
                     "if (#{actual_condition}) then (#{presence_logic}) else true()"
                   else
                     "true()"
                   end

      # Sett sammen og lagre
      final_xpath = conditions.any? ? "if (#{conditions.join(' and ')}) then (#{clean_test}) else true()" : clean_test
      final_xpath = apply_legal_basis_noid_exemption(final_xpath, params, mapping, context)

      result[target_info['field_id']] ||= []
      result[target_info['field_id']] << {
        'id'      => NationalRulesHelpers.rule_id(domain: meta['domain'], kind: meta['kind'], scope: meta['scope'] || 'nat', index: rule['index'] || (idx + 1)),
        'test'    => NationalRulesHelpers.clean_xpath("if (exists(#{subject})) then (#{final_xpath}) else true()"),
        'message' => NationalRulesHelpers.extract_message(rule, meta)
      }
    end
    result
  end
  
  # 12. Logikk på tvers av felter
  def self.cross_field_logic(params, meta, context)
    mapping = context[:mapping]
    result = {}
    context_node = params['context_node'] || "ND-Root"
    result[context_node] ||= []

    patterns = {
      'mutual_existence' => [
        { key: 'parent_missing', test: "not({{child}}) or exists({{parent}})" },
        { key: 'child_missing',  test: "not({{parent}}) or (count({{container}}) = count({{child}}))" }
      ]
    }

    global_offset = -1

    Array(params['relations']).each do |rel|
      pattern_templates = patterns[rel['type']] || raise("Ukjent logikk-type: #{rel['type']}")
      
      paths = {
        'parent'    => mapping.dig(rel['parent_key'], 'xpath'),
        'child'     => mapping.dig(rel['child_key'], 'xpath'),
        'container' => mapping.dig(rel['container_key'], 'xpath')
      }

      pattern_templates.each do |template|
        test_expr = template[:test].dup
        paths.each { |id, xpath| test_expr.gsub!("{{#{id}}}", xpath) if xpath }

        current_stable_index = (rel['index'].to_i) + global_offset
        
        # Henter ut meldings-objektet (nob, nno, eng)
        msg_obj = rel[template[:key]]
        
        # Her henter vi eng-strengen direkte siden det er den du vil ha ut
        message = msg_obj['eng'] || "Missing English message"

        result[context_node] << {
          'id'      => NationalRulesHelpers.rule_id(
            domain: meta['domain'],
            scope:  rel['scope'] || meta['scope'] || 'global',
            kind:   meta['kind']&.to_sym || :consistency,
            index:  current_stable_index
          ),
          'test'    => NationalRulesHelpers.clean_xpath(test_expr),
          'message' => message
        }
        global_offset += 1
      end
      
      # Justerer offset så neste relasjon fortsetter bokstavrekken
      global_offset -= 1 
    end
    result
  end

  def self.apply_legal_basis_noid_exemption(core_xpath, params, mapping, context)
    # Sjekk om denne regelen i det hele tatt skal kunne overstyres av lovhjemmel
    trigger_value = params.dig('override_if', 'legal_basis_noid')
    return core_xpath if trigger_value.nil?
  
    deps = params['_dependencies']
    return core_xpath unless deps
  
    # 1. Hent unntaksdefinisjonen fra lb_registry (f.eks. EXEMPT)
    lb_registry_cfg = deps['external_data']&.find { |d| d['id'] == 'lb_registry' }
    lb_data = YAML.load_file(File.join(context[:base], lb_registry_cfg['file']))
    exempt_entry = lb_data['definitions']['entries'].find { |e| e['regulation'] == trigger_value }
    
    return core_xpath unless exempt_entry
  
    # 2. Bygg "Vaktposten" basert på de norske og engelske beskrivelsesfeltene
    # Vi bruker mappingen for å finne de faktiske XPath-stiene til BT-01(f)
    exemption_checks = Array(deps['fields']['legal_basis_descriptions']).map do |d|
      path = mapping.dig(d['legal_basis_description'], 'xpath')
      lang = d['lang'].to_s.downcase
      text = exempt_entry.dig('code', lang)
      
      "normalize-space(#{path}) = '#{text.strip.gsub("'", "&apos;")}'" if path && text
    end.compact
  
    # 3. Smokk det sammen: if (not(unntatt)) then (original test) else true()
    is_not_exempt = "not(#{exemption_checks.join(' or ')})"
    
    "if (#{is_not_exempt}) then (#{core_xpath}) else true()"
  end
end

# --- 4. EXECUTION ---
logic_type = raw_data['logic']
meta = raw_data['_rule'] || {}
payload = (logic_type == 'national_tailored_codelist_pair') ? raw_data : (raw_data['params'] || {})

# Vi pakker alt inn i context-objektet
context = {
  mapping: FIELD_MAPPING,
  base: options[:base],
  eu_codelists: options[:eu_codelists],
  no_codelists: options[:no_codelists],
  external_data: options[:external_data]
}

if FragmentHandlers.respond_to?(logic_type)
  result_hash = FragmentHandlers.send(logic_type, payload, meta, context)
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
