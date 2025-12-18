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
require_relative 'yaml_text_folder'
require_relative 'national_rules_helpers'

# 1. Konfigurasjon av stier
BASE = Pathname.new(__dir__).join('../../..').expand_path
POLICY_DIR = BASE.join('src/policy/national')
HEADER_PATH = POLICY_DIR.join("templates/LICENSE_HEADER.fragment.txt")
REGISTRY_PATH = POLICY_DIR.join("rule_id_registry.yaml")
MAPPING_PATH = POLICY_DIR.join("eforms_fields_mapping.yaml")

# Sørg for at register og mapping er lastet
begin
  RuleIdRegistry.load(REGISTRY_PATH)
  FIELD_MAPPING = YAML.load_file(MAPPING_PATH)
rescue => e
  abort "❌ Fatal: Kunne ikke laste konfigurasjon: #{e.message}"
end

# 2. Parse argumenter (Kun input og output nå)
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_fragments.rb [options]"
  opts.on("-i", "--input FILE", "Input file name (relative to POLICY_DIR)") { |v| options[:input] = v }
  opts.on("-o", "--output FILE", "Output file name (relative to generated dir)") { |v| options[:output] = v }
end.parse!

raise "Missing arguments: -i and -o are required" unless options[:input] && options[:output]

INPUT_PATH  = options[:input].start_with?('/') ? Pathname.new(options[:input]) : POLICY_DIR.join(options[:input])
OUTPUT_PATH = BASE.join('src/generated/national', options[:output])

# 3. Laste data og detektere type
raw_data = YAML.load_file(INPUT_PATH)

# --- TYPE DETEKSJON ---
# Vi sjekker strukturen for å finne ut hvilken handler som skal brukes
type = case
       when raw_data['logic']
         :field_logic    # Ny stil: split_whitelist, any_of etc.
       when raw_data.key?('base') && raw_data.key?('_settings')
         :codelist_rule  # Codelist generator
       when raw_data.values.any? { |v| v.is_a?(Hash) && v.key?('mandatory') }
         :mandatory      # Tradisjonell mandatory-sjekk
       when raw_data.values.any? { |v| v.is_a?(Hash) && (v.key?('_rules') || v.key?('test')) }
         :field_list     # Tradisjonell feltliste (gammel stil)
       when raw_data.keys.all? { |k| k =~ /^[A-Z0-9-]{3,6}$/ } 
         :notice_types   # Enkel kodeliste (f.eks. notice types)
       else
         abort "❌ Kunne ikke detektere regel-type for #{options[:input]}. Sjekk YAML-struktur."
       end

# 4. Handlers
body = case type
       when :field_logic
         meta = raw_data['_rule'] || raise("Missing _rule metadata in #{options[:input]}")
         
         if raw_data['logic'] == 'any_of'
           xpath_test = NationalRulesHelpers.build_consistency_xpath(raw_data['logic'], raw_data['params'], FIELD_MAPPING)
           id = NationalRulesHelpers.rule_id(domain: meta['domain'], scope: meta['scope'], kind: meta['kind'].to_sym, index: 0)
           
           "ND-Root:\n  - id: #{id}\n    test: >-\n      #{NationalRulesHelpers.clean_xpath(xpath_test)}\n    message: >-\n      #{NationalRulesHelpers.clean_prosa(raw_data.dig('description', 'eng'))}\n"
           
         elsif raw_data['logic'] == 'split_whitelist'
           rules = NationalRulesHelpers.build_split_whitelist(raw_data['params'], BASE, meta['domain'], FIELD_MAPPING)
           out = +""
           rules.each do |r|
             out << "#{r['field_id']}:\n  - id: #{r['id']}\n    test: >-\n      #{NationalRulesHelpers.clean_xpath(r['test'])}\n    message: >-\n      #{NationalRulesHelpers.clean_prosa(r['message'])}\n"
           end
           out
         end

       when :codelist_rule
         rule_obj = NationalRulesHelpers.generate_codelist_rule(INPUT_PATH)
         field_name = INPUT_PATH.basename.to_s.split('.').first
         "#{field_name}:\n  - id: #{rule_obj['id']}\n    test: >-\n      #{NationalRulesHelpers.clean_xpath(rule_obj['test'])}\n    message: >-\n      #{rule_obj['message']}"

       when :mandatory
         fields = NationalRulesHelpers.deep_prune_unwanted_metadata!(raw_data)
         out = +""
         fields.each do |field_name, field_def|
           next unless (m = field_def['mandatory'])
           rule_meta = field_def['_rule'] || raise("Field #{field_name} missing _rule")
           Array(m['constraints']).each_with_index do |constraint, i|
             id = NationalRulesHelpers.rule_id(domain: rule_meta['domain'], scope: rule_meta['scope'], kind: m['kind'].to_sym, index: i)
             count_expr = m['kind'] == 'cardinality' ? "count(#{field_def['xpath']}) = 1" : "count(#{field_def['xpath']}) >= 1"
             out << "#{field_name}:\n  - id: #{id}\n    context: \"/*\"\n    test: >-\n      #{NationalRulesHelpers.clean_xpath(count_expr)}\n    message: >-\n      #{constraint.dig('_rationale', 'eng')}\n"
           end
         end
         out

       when :field_list
         data = NationalRulesHelpers.deep_prune_unwanted_metadata!(raw_data)
         out = +""
         data.each do |field_name, field_def|
           rules = field_def['_rules'] || [field_def].flatten
           rules.each_with_index do |r, i|
             next unless r['test']
             rm = r['_rule'] || {}
             id = NationalRulesHelpers.rule_id(domain: rm['domain'] || 'DT', scope: rm['scope'] || 'global', kind: (rm['kind'] || 'whitelist').to_sym, index: i)
             out << "#{field_name}:\n  - id: #{id}\n    context: \"#{r['context'] || '/*'}\"\n    test: >-\n      #{NationalRulesHelpers.clean_xpath(r['test'])}\n    message: >-\n      #{NationalRulesHelpers.clean_prosa(r.dig('_rationale', 'eng') || r['message'])}\n"
           end
         end
         out

       when :notice_types
         types = raw_data.keys.sort
         id = NationalRulesHelpers.rule_id(domain: 'NT', scope: 'global', kind: :whitelist, index: 0)
         "OPP-070-notice:\n  - id: #{id}\n    test: >-\n      #{NationalRulesHelpers.xpath_whitelist(types)}\n    message: >-\n      Notice type must be #{types[0..-2].join(', ')} or #{types.last}."
       end

# 5. Lagring
if body && !body.empty?
  header = NationalRulesHelpers.load_header(HEADER_PATH, OUTPUT_PATH.basename.to_s)
  File.write(OUTPUT_PATH, header + "---\n" + body)
  puts "✅ Generated: #{options[:input]} -> #{options[:output]}"
else
  abort "❌ Ingen data generert for #{options[:input]}"
end
