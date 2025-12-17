#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'yaml_text_folder.rb'

BASE = File.expand_path('../../..', __dir__)

def load_yaml(rel)
  YAML.load_file(File.join(BASE, rel))
end

def threshold_phrase(entry)
  case entry['threshold_scope']
  when 'national'
    'mindre enn de nasjonale terskelverdiene'
  when 'national_to_eu'
    'over de nasjonale terskelverdiene, og mindre enn EØS-terskelverdiene'
  when 'eu'
    'under EØS-terskelverdiene'
  else
    raise "Unknown threshold_scope: #{entry['threshold_scope']}"
  end
end

def part_text(part)
  Array(part).join(' og ')
end

def render(template, vars)
  template.gsub(/\{\{\s*(\w+)\s*\}\}/) do
    key = Regexp.last_match(1)
    vars.fetch(key) { raise "Missing template variable: #{key}" }
  end
end

# --- Load inputs --------------------------------------------------

legal_basis_ssot = load_yaml('src/ruleset_sources/national/national-procedure-legal-basis-ssot.yaml')
regulations_codelist = load_yaml('src/ruleset_sources/national/national-procurement-regulations-codelist.yaml')
legal_basis_text_template  = load_yaml('src/ruleset_sources/national/texts/national-procedure-legal-basis-text-template.yaml')

# --- Build explanations ------------------------------------------

blocks = legal_basis_ssot['entries'].map do |entry|
  reg = regulations_codelist.fetch(entry['regulation'])
  
  explanation = nil
  e_text_content = nil

  if entry['regulation'] == 'EXEMPT'
    # SPECIAL CASE: EXEMPT FROM THE REGULATIONS
    explanation = "Oppdragsgiver er ikke underlagt lov eller forskrift om offentlige anskaffelser."
    e_text_content = reg['name']['nob'] 
    
  else
    # REGULAR CASE 
    explanation = render(
      legal_basis_text_template['legal_basis_explanation']['nob'],
      {
        'threshold_phrase' => threshold_phrase(entry),
        'regulation_name'  => reg['name']['nob'],
        'section'          => entry['section'],
        'part'             => part_text(entry['part'])
      }
    ).strip
    
    e_text_content = "#{reg['name']['nob']} Del #{part_text(entry['part'])}"
  end
  
  <<~YAML.chomp
  - code: #{entry['code']}
  #{YamlText.folded('  e_text', e_text_content, indent: 4)}
  #{YamlText.folded('  f_text', explanation, indent: 4)}
  YAML
end

# --- Emit YAML ----------------------------------------------------

yaml = <<~YAML
generated: true
license: CC-BY-4.0
spdx: CC-BY-4.0
license_url: https://creativecommons.org/licenses/by/4.0/
source: national-procedure-legal-basos-ssot
legal_basis:
#{blocks.join("\n")}
YAML

out_path = File.join(BASE, 'src/generated/national/legal-basis.intermediate.yaml')
FileUtils.mkdir_p(File.dirname(out_path))
File.write(out_path, yaml)

puts "Generated #{out_path}"
