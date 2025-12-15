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
# Strip human-only metadata from fields
# ------------------------------------------------------------

fields.each_value do |field_def|
  next unless field_def.is_a?(Hash)

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
# Aliases (deterministic, trivial for now)
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
# Load rule fragments (machine-facing)
# ------------------------------------------------------------

rules = {}

Dir[FRAGMENTS_DIR.join('*.rules.fragment.yaml')].sort.each do |path|
  fragment = YAML.load_file(path)

  fragment.each do |bt, entries|
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

File.write(OUT_PATH, out.to_yaml)

puts "Assembled national ruleset:"
puts "  #{OUT_PATH}"
puts "Notice types: #{notice_types.join(', ')}"
puts "Fields: #{fields.keys.sort.join(', ')}"
puts "Rule blocks: #{rules.keys.sort.join(', ')}"
