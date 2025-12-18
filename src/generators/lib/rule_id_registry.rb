#!/usr/local/bin/ruby
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

module RuleIdRegistry
  class << self
    attr_reader :data

    # 1. Metoden som "primer" modulen med data
    def load(path)
      pathname = Pathname.new(path)
      raise "Registry file not found at #{path}" unless pathname.exist?
      
      @data = YAML.load_file(pathname).freeze
      validate! # Vi validerer alltid ved lasting for å sikre integritet
    end

    # 2. Oppslag krever nå at data er lastet
    def group(domain:, kind:, scope: 'global')
      ensure_loaded!

      domain_map = @data.fetch(domain.to_s) { raise KeyError, "Registry: Ukjent domene '#{domain}'" }
      scope_map  = domain_map.fetch(scope.to_s) { raise KeyError, "Registry: Ukjent scope '#{scope}'" }
      val        = scope_map.fetch(kind.to_s) { raise KeyError, "Registry: Ukjent type '#{kind}'" }

      unless val.is_a?(Integer)
        raise TypeError, "Registry: #{domain}.#{scope}.#{kind} må være Integer, fant #{val.class}"
      end

      val
    end

    def validate!
      ensure_loaded!
      seen_ids = {}

      @data.each do |domain, scopes|
        next if domain == 'metadata' || domain.start_with?('_')
        
        scopes.each do |scope, kinds|
          next if scope.start_with?('_')
          
          kinds.each do |kind, group|
            next if kind.start_with?('_')
            
            composite_id = "#{domain}-#{group}"
            path = "#{domain}.#{scope}.#{kind}"

            if seen_ids.key?(composite_id)
              raise "!!! KOLLISJON I REGISTRY !!!\n" \
                    "Gruppenummer '#{group}' brukt flere ganger i domene '#{domain}'.\n" \
                    "Eksisterende: #{seen_ids[composite_id]}\n" \
                    "Ny kollisjon: #{path}"
            end
            seen_ids[composite_id] = path
          end
        end
      end
      true
    end

    private

    def ensure_loaded!
      raise "RuleIdRegistry not loaded! Call RuleIdRegistry.load(path) first." if @data.nil?
    end
  end
end

# Helt nederst i fila, etter "module RuleIdRegistry ... end"

if __FILE__ == $0
  # 1. Hent sti fra kommandolinjen, eller bruk en fornuftig standard
  input_path = ARGV[0] || File.expand_path('../../policy/national/rule_id_registry.yaml', __dir__)
  
  begin
    puts "Validating registry: #{input_path}"
    RuleIdRegistry.load(input_path)
    puts "Registry validated successfully. Found #{RuleIdRegistry.data.keys.count - 1} domains."
  rescue => e
    puts "Registry validation failed: #{e.message}"
    # Valgfritt: Vis hvor den faktisk lette hvis fila ikke ble funnet
    if e.message.include?("not found")
      puts "   Current working directory: #{Dir.pwd}"
    end
    exit 1
  end
end
