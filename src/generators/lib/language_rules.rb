#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

require_relative 'rule_index'
require_relative 'yaml_text_folder'

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

BASE = File.expand_path('../../..', __dir__)

CODELIST_PATH =
  File.join(
    BASE,
    'src/codelists/eu-official-language.yaml'
  )

POLICY_PATH =
  File.join(
    BASE,
    'src/policy/national/languages.yaml'
  )

OUT_PATH =
  File.join(
    BASE,
    'src/generated/national/language.rules.fragment.yaml'
  )

# ------------------------------------------------------------
# Load data
# ------------------------------------------------------------

codelist =
  YAML.load_file(CODELIST_PATH)

policy =
  YAML.load_file(POLICY_PATH)

# ------------------------------------------------------------
# Resolve allowed languages
# ------------------------------------------------------------

allowed =
  codelist.keys +
  Array(policy['include'])

allowed.uniq!
allowed.sort!

puts "Resolved #{allowed.size} allowed languages"

# ------------------------------------------------------------
# Validate rule index
# ------------------------------------------------------------

RuleIndex.validate!

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def alpha_index(n)
  s = +""
  while n >= 0
    s.prepend((n % 26 + 'A'.ord).chr)
    n = n / 26 - 1
  end
  s
end

def rule_id(domain:, scope:, kind:, index:)
  format(
    "EFORMS-NOR-NATIONAL-%s-R%03d%s",
    domain,
    RuleIndex.group(domain: domain, scope: scope, kind: kind),
    alpha_index(index)
  )
end

def emit_whitelist(field:, rule_id:, values:, message:)
<<~YAML
#{field}:
  - id: #{rule_id}
    test: >-
      normalize-space() = (
#{values.map { |v| "        '#{v}'" }.join(",\n")}
      )
    message: >-
      #{message}
  
YAML
end

# ------------------------------------------------------------
# Generate rules
# ------------------------------------------------------------

out = +""

rules = [
  {
    field: 'BT-702(a)-notice',
    scope: :main,
    message: 'Main language must be Norwegian or one of the official languages.'
  },
  {
    field: 'BT-702(b)-notice',
    scope: :additional,
    message: 'Additional language must be Norwegian or one of the official languages.'
  }
]

rules.each_with_index do |spec, i|
  out << emit_whitelist(
    field: spec[:field],
    rule_id: rule_id(
      domain: 'NL', 
      scope: spec[:scope],
      kind: :whitelist, 
      index: i
    ),
    values: allowed,
    message: spec[:message]
  )
end

# ------------------------------------------------------------
# Write output
# ------------------------------------------------------------

File.write(OUT_PATH, out)

puts "Wrote language rules fragment to:"
puts "  #{OUT_PATH}"
