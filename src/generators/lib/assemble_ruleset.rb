#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

BASE = Pathname.new(__dir__).join('../../..').expand_path

FRAGMENTS_DIR =
  BASE.join('src/generated/national')

OUT_PATH =
  BASE.join('src/generated/national/national.rules.yaml')


# ------------------------------------------------------------
# Load notice types
# ------------------------------------------------------------

notice_types_def =
  YAML.load_file(POLICY_DIR.join('notice-types.yaml'))

# Hent nøklene (E2, E3, E4 osv.) og konverter til strenger
notice_types = notice_types_def.keys.map(&:to_s).sort

# ------------------------------------------------------------
# Load fragments
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
# Assemble final ruleset
# ------------------------------------------------------------

out = {
  'noticeTypes' => notice_types,
  'rules' => rules,
  'removed' => []
}

File.write(OUT_PATH, out.to_yaml(line_width: 70))

puts "Assembled ruleset:"
puts "  #{OUT_PATH}"
