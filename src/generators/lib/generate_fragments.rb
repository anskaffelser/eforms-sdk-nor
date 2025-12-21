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

#!/usr/bin/env ruby
# frozen_string_literal: true

# =====================================================================
# Copyright © 2025 DFØ – The Norwegian Agency for Public and Financial
# Management
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
    
    # 1. Hent rådata fra kodelistene
    raw_codes = NationalRulesHelpers.resolve_codes(params, eu_dir)
    
    # 2. Vask bort Hasher slik at vi kun står igjen med selve kodene (string) 🧼
    clean_codes = raw_codes.map { |c| c.is_a?(Hash) ? c['type'] : c }
    
    # 3. Formater kodene med apostrofer for XPath (f.eks. "'E2', 'E3'") 🛠️
    formatted_codes = clean_codes.map { |c| "'#{c}'" }.join(', ')
    
    # Resten av forberedelsene
    id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: meta['scope'], kind: meta['kind']&.to_sym || :technical, index: 0)
    msg = NationalRulesHelpers.extract_message(params, meta)

    result = {}

    # Logikk for konsistens (flere felt samtidig)
    if meta['kind'] == 'consistency' || targets.size > 1
      main_lang_xpath = mapping['main_notice_language']&.fetch('xpath') 
      additional_lang_xpath = mapping['additional_notice_language']&.fetch('xpath')

      # Her bruker vi den ferdig vaskede formatted_codes
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
      
    # Logikk for enkeltfelt-validering
    else
      targets.each do |t_key|
        t_info = mapping[t_key] || raise("Ukjent target: #{t_key}")
        
        # Også her bruker vi den ferdig vaskede formatted_codes
        test = "normalize-space() = (#{formatted_codes})"
        
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
end

# --- 4. EXECUTION ---
logic_type = raw_data['logic']
meta = raw_data['_rule'] || {}
params = raw_data['params'] || {}

if FragmentHandlers.respond_to?(logic_type)
  result_hash = FragmentHandlers.send(logic_type, params, meta, FIELD_MAPPING, options[:base], options[:eu_codelists])
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
