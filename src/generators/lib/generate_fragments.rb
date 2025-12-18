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

# --- 1. CONFIG & SETUP ---
BASE = Pathname.new(__dir__).join('../../..').expand_path
POLICY_DIR = BASE.join('src/policy/national')
HEADER_PATH = POLICY_DIR.join("templates/LICENSE_HEADER.fragment.txt")
MAPPING_PATH = POLICY_DIR.join("eforms_fields_mapping.yaml")

# --- 1.5 INITIALIZE REGISTRY ---
REGISTRY_PATH = POLICY_DIR.join("rule_id_registry.yaml")
begin
  RuleIdRegistry.load(REGISTRY_PATH)
rescue => e
  abort "❌ Kunne ikke laste RuleIdRegistry: #{e.message}"
end

# --- 2. DATA LOADERS ---
def load_field_mapping
  YAML.load_file(MAPPING_PATH)
rescue => e
  abort "❌ Kunne ikke laste mapping: #{e.message}"
end

def load_input_data(path)
  # Vi bruker load_stream for å håndtere filer med metadata-hode (---)
  docs = YAML.load_stream(File.read(path))
  # Finn dokumentet som inneholder selve logikken (hopp over metadata)
  docs.find { |d| d && (d.key?('logic') || d.key?('params') || d.key?('base')) }
end

# --- 3. HANDLER ENGINE (Strategy Pattern) ---
# --- 3. HANDLER ENGINE (Strategy Pattern) ---
module FragmentHandlers
  # 1. Genererer mellomformatet (.fields.fragment.yaml)
  def self.mandatory_requirements(params, meta, mapping)
    cond = params['condition']
    source_path = POLICY_DIR.join(cond['source_folder'] || '', cond['source_file'])
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
          'constraints' => [{ 'noticeTypes' => codes.dup }] # .dup hindrer aliaser
        }
      }
    end
    result
  end

  # 2. Genererer kodelistevalidering og språkkonsistens (.rules.fragment.yaml)
  def self.any_of(params, meta, mapping)
    targets = Array(params['targets'] || params['target'])
    codes = Array(params['codes'] || params['code']).map { |c| c['type'] || c }
    id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: meta['scope'], kind: meta['kind'].to_sym, index: 0)
    msg = NationalRulesHelpers.clean_prosa(params.dig('description', 'eng') || meta['description'])

    result = {}
    
    # Spesialhåndtering for språk-konsistens
    if meta['kind'] == 'consistency' || targets.size > 1
      formatted_codes = codes.map { |c| "'#{c}'" }.join(', ')
      main_lang_xpath = mapping['main_notice_language']['xpath'] 
      additional_lang_xpath = mapping['additional_notice_language']['xpath']

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
    else
      # Standard for enkeltfelt
      targets.each do |t_key|
        t_info = mapping[t_key] || raise("Ukjent target: #{t_key}")
        test = "normalize-space() = (#{codes.map { |c| "'#{c}'" }.join(', ')})"
        result[t_info['field_id']] = [{
          'id' => id,
          'test' => NationalRulesHelpers.clean_xpath(test),
          'message' => msg
        }]
      end
    end
    result
  end

  # 3. Genererer splittede whitelists (f.eks. org-nr, valuta)
  def self.split_whitelist(params, meta, mapping)
    raw_rules = NationalRulesHelpers.build_split_whitelist(
      params, 
      BASE, 
      meta['domain'], 
      mapping
    )

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
end

# --- 4. MAIN EXECUTION ---
options = {}
OptionParser.new { |opts|
  opts.on("-i", "--input FILE") { |v| options[:input] = v }
  opts.on("-o", "--output FILE") { |v| options[:output] = v }
}.parse!

FIELD_MAPPING = load_field_mapping
raw_data = load_input_data(POLICY_DIR.join(options[:input]))
abort "❌ Fant ingen logikk i #{options[:input]}" unless raw_data

# Detekter hvilken logikk-handler som skal brukes
logic_type = raw_data['logic']
meta = raw_data['_rule'] || {}
params = raw_data['params'] || {}

# Kjør handleren
if FragmentHandlers.respond_to?(logic_type)
  result_hash = FragmentHandlers.send(logic_type, params, meta, FIELD_MAPPING)
else
  abort "❌ Ukjent logikk-type: #{logic_type}"
end

# --- 5. OUTPUT ---
if result_hash && !result_hash.empty?
  output_path = BASE.join('src/generated/national', options[:output])
  output_path.dirname.mkpath
  
  header = NationalRulesHelpers.load_header(HEADER_PATH, output_path.basename.to_s)
  
  # Bruk to_yaml for å sikre korrekt escaping og struktur
  File.write(output_path, header + result_hash.to_yaml(line_width: -1))
  puts "✅ Generated: #{options[:output]}"
else
  abort "❌ Ingen data produsert."
end
