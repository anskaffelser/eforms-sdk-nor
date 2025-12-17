#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'


# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

BASE = Pathname.new(__dir__).join('../../..').expand_path

POLICY_DIR    = BASE.join('src/policy/national')
FRAGMENTS_DIR = BASE.join('src/generated/national')

OUT_PATH =
  BASE.join('src/fields/national.rules.yaml')

HEADER_PATH = POLICY_DIR.join("LICENSE_HEADER.monolith.txt")

# ------------------------------------------------------------
# Load and enrich header
# ------------------------------------------------------------

raw_header = File.read(HEADER_PATH)

header = raw_header.gsub('<OUTPUT_FILENAME>', OUT_PATH.basename.to_s)

# ------------------------------------------------------------
# Load policy (human-facing, high-level)
# ------------------------------------------------------------

notice_types_def =
  YAML.load_file(POLICY_DIR.join('notice_types.yaml'))

fields =
  YAML.load_file(POLICY_DIR.join('fields.yaml'))

profiles =
  YAML.load_file(POLICY_DIR.join('profiles.yaml'))

# ------------------------------------------------------------
# Strip human-only metadata from fields, 
# and clean XPaths in fields definitions
# ------------------------------------------------------------

fields.each_value do |field_def|
  next unless field_def.is_a?(Hash)
  
  if xpath = field_def['xpath']
    # 1. Fjern alle linjeskift og komprimer whitespace.
    clean_xpath = xpath
                  .gsub(/[\r\n]+/, ' ') # Erstatter linjeskift med mellomrom
                  .gsub(/\s*\/\s*/, '/') # Fikser ' / ' til '/'
                  .gsub(/\s*\*\s*/, '*') # Fikser ' * ' til '*'                 
                  .gsub(/\s+/, ' ') # Komprimerer gjenværende whitespace
                  .strip
                  
    field_def['xpath'] = clean_xpath
  end

  mandatory = field_def['mandatory']
  next unless mandatory.is_a?(Hash)

  mandatory.delete('_rationale')

  if constraints = mandatory['constraints']
    constraints.each do |c|
      c.delete('_rationale')
    end
  end
end


# ------------------------------------------------------------
# Resolve noticeTypes with sanity checks
# ------------------------------------------------------------

defined_notice_types =
  notice_types_def.keys.map(&:to_s).sort

used_notice_types =
  profiles
    .values
    .flat_map { |p| Array(p['noticeTypes']) }
    .map(&:to_s)
    .uniq
    .sort

# Sanity check: profiles must only reference defined notice types
unknown =
  used_notice_types - defined_notice_types

unless unknown.empty?
  raise <<~MSG
    Profiles reference unknown notice types:
      #{unknown.join(', ')}

    Defined notice types:
      #{defined_notice_types.join(', ')}
  MSG
end

notice_types = used_notice_types

# ------------------------------------------------------------
# Aliases are derived from 
# ------------------------------------------------------------

aliases =
  notice_types.to_h { |nt| [nt, nt] }

# ------------------------------------------------------------
# Fold profiles → fields
# ------------------------------------------------------------
# Profiles are NOT emitted directly.
# They materialize as field definitions and rules.

profiles.each do |_profile_name, profile|
  # Customization ID → field.pattern
  if cid = profile['customization_id']
    field   = cid.fetch('field')
    pattern = cid.fetch('pattern')

    fields[field] ||= {}
    fields[field]['pattern'] ||= {}
    fields[field]['pattern']['value'] = pattern
  end
end

# ------------------------------------------------------------
# Helpers for content cleanup
# ------------------------------------------------------------

def clean_string_content(content, aggressive_xpath_cleanup: false)
  return content unless content.is_a?(String)

  clean_content = content
                  .gsub(/[\r\n]+/, ' ') # 1. Erstatter linjeskift med enkelt mellomrom
                  .gsub(/\s+/, ' ')    # 2. Komprimerer gjenværende whitespace til ett mellomrom
                  .gsub(/('\s+)/, "'").gsub(/(\s+')/, "'") # 3. Fjern mellomrom rett etter åpningsfnutter og rett før lukkefnutter. 

  if aggressive_xpath_cleanup
    # 4. Aggressiv fjerning av ALLE mellomrom rundt XPath-separatorer
    clean_content = clean_content
                    .gsub(/\s*\/\s*/, '/') # Fikser ' / ' til '/'
                    .gsub(/\s*\*\s*/, '*') # Fikser ' * ' til '*'
  end
  
  clean_content.strip
end

# ------------------------------------------------------------
# Load rule fragments (machine-facing)
# ------------------------------------------------------------

rules = {}

Dir[FRAGMENTS_DIR.join('*.rules.fragment.yaml')].sort.each do |path|
  fragment = YAML.load_file(path)

  fragment.each do |bt, entries|
    
    entries.each do |rule|
      
      # 1. Rens context og test aggressivt (XPath)
      ['context', 'test'].each do |key|
        if rule[key]
          # Bruk aggressiv cleanup for å fjerne whitespace rundt / og *
          rule[key] = clean_string_content(rule[key], aggressive_xpath_cleanup: true)
        end
      end
      
      # 2. Rens message (Prosa)
      if rule['message']
        # Bruk standard cleanup for å fjerne \n, men behold normal whitespace
        rule['message'] = clean_string_content(rule['message'], aggressive_xpath_cleanup: false)
      end
    end
    
    rules[bt] ||= []
    rules[bt].concat(entries)
  end
end

# ------------------------------------------------------------
# Assemble final monolith
# ------------------------------------------------------------

out = {
  'noticeTypes' => notice_types,
  'aliases'     => aliases,
  'fields'      => fields,
  'rules'       => rules,
  'removed'     => []
}

# ------------------------------------------------------------
# Write output
# ------------------------------------------------------------

yaml_content = out.to_yaml(line_width: 1_000_000)

final_output = header + yaml_content

File.write(OUT_PATH, final_output)

puts "Assembled national ruleset:"
puts "  #{OUT_PATH}"
puts "Notice types: #{notice_types.join(', ')}"
puts "Fields: #{fields.keys.sort.join(', ')}"
puts "Rule blocks: #{rules.keys.sort.join(', ')}"
