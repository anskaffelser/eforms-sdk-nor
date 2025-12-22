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
end.parse!

[:input, :output, :mapping, :registry, :license, :base, :eu_codelists].each do |opt|
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
  def self.mandatory_requirements(params, meta, mapping, base_dir, _eu_dir)
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
  def self.any_of(params, meta, mapping, _base_dir, eu_dir)
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
  def self.split_whitelist(params, meta, mapping, base_dir, eu_dir)
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
  def self.pattern(params, meta, mapping, _base_dir, _eu_dir)
    target = params['target'] || raise("Mangler target for pattern-regel")
    t_info = mapping[target] || raise("Ukjent target: #{target}")
    
    pattern = params['pattern']
    id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: meta['scope'], kind: :pattern, index: 0)
    
    # 🌟 Bruker den nye felles metoden for meldinger
    msg = NationalRulesHelpers.extract_message(params, meta)

    test = "matches(normalize-space(), '#{pattern}')"

    {
      t_info['field_id'] => [{
        'id' => id,
        'test' => test,
        'message' => msg
      }]
    }
  end
  
  # 5. National Tailored Codelist Pair (.rules.fragment.yaml)
  def self.national_tailored_codelist_pair(data, meta, mapping, _base_dir, _eu_dir)
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
  result_hash = FragmentHandlers.send(logic_type, payload, meta, FIELD_MAPPING, options[:base], options[:eu_codelists])
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
