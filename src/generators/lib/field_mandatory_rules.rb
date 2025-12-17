#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

require_relative 'rule_index'
require_relative 'yaml_text_folder'

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

BASE = Pathname.new(__dir__).join('../../..').expand_path

POLICY_DIR = BASE.join('src/policy/national')

FIELDS_PATH = POLICY_DIR.join('fields.yaml')

OUT_PATH = BASE.join('src/generated/national/field-mandatory.rules.fragment.yaml')

HEADER_PATH = POLICY_DIR.join("LICENSE_HEADER.fragment.txt")



# ------------------------------------------------------------
# Load and enrich header
# ------------------------------------------------------------

raw_header = File.read(HEADER_PATH)

header = raw_header.gsub('<FRAGMENT_FILENAME>', OUT_PATH.basename.to_s)

# ------------------------------------------------------------
# Load input
# ------------------------------------------------------------

fields = YAML.load_file(FIELDS_PATH)

puts "Loaded #{fields.size} fields"

# ------------------------------------------------------------
# Validate rule index
# ------------------------------------------------------------

RuleIndex.validate!

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

# Deterministic A, B, ..., Z, AA, AB, ...
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

# LB-scope er semantisk, ikke teknisk
def lb_scope_for(field_name)
  case field_name
  when /-01\(e\)-/
    'name'
  when /-01\(f\)-/
    'description'
  else
    raise "Cannot determine LB scope for field #{field_name}"
  end
end

def count_test(xpath, kind)
  case kind
  when 'cardinality'
    <<~XPATH.strip
      count(
      #{xpath}
      ) = 1
    XPATH
  when 'presence'
    <<~XPATH.strip
      count(
      #{xpath}
      ) >= 1
    XPATH
  else
    raise "Unknown mandatory kind: #{kind.inspect}"
  end
end

# ------------------------------------------------------------
# Generate rules
# ------------------------------------------------------------

out = +""

fields.each do |field_name, field_def|
  mandatory = field_def['mandatory']
  next unless mandatory

  xpath =
    field_def.fetch('xpath') do
      raise "Field #{field_name} has mandatory rule but no xpath"
    end

  kind =
    mandatory.fetch('kind') do
      raise "Field #{field_name} mandatory rule missing kind"
    end

  constraints =
    Array(
      mandatory.fetch('constraints') do
        raise "Field #{field_name} mandatory rule missing constraints"
      end
    )

  constraints.each_with_index do |constraint, i|
    rationale =
      constraint
        .fetch('_rationale') { {} }
        .fetch('eng') do
          raise "Field #{field_name} constraint missing eng rationale"
        end

    test_expr =
      count_test(
        YamlText.folded_lines(xpath.strip, indent: 8),
        kind
      )

    out << <<~YAML
    #{field_name}:
      - id: #{rule_id(
        domain: 'LB',
        scope: lb_scope_for(field_name),
        kind: kind.to_sym,
        index: i
      )}
        context: "/*"
        test: >-
    #{YamlText.folded_lines(test_expr, indent: 8)}
        message: >-
          #{rationale}

    YAML
  end
end

# ------------------------------------------------------------
# Write output
# ------------------------------------------------------------

final_output = header + "---\n" + out

File.write(OUT_PATH, final_output)

puts "Wrote mandatory field rules fragment to:"
puts "  #{OUT_PATH}"
