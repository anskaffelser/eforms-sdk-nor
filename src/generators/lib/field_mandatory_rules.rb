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

def deep_prune_unwanted_metadata!(object)
  case object
  when Hash
    object.delete('_derivedRequirements')
    # Vi beholder _rule og _rationale, sletter resten med understrek
    object.delete_if { |k, _| k.to_s.start_with?('_') && !['_rule', '_rationale'].include?(k.to_s) }
    object.each_value { |v| deep_prune_unwanted_metadata!(v) }
  when Array
    object.each { |v| deep_prune_unwanted_metadata!(v) }
  end
  object
end

raw_input = YAML.load_file(FIELDS_PATH)
fields = deep_prune_unwanted_metadata!(raw_input)

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
  # Vi fjerner linjeskift og dobbel whitespace fra XPathen før vi pakker den inn
  clean_xpath = xpath.gsub(/\s+/, ' ').strip
  
  case kind
  when 'cardinality'
    "count(#{clean_xpath}) = 1"
  when 'presence'
    "count(#{clean_xpath}) >= 1"
  else
    raise "Unknown mandatory kind: #{kind.inspect}"
  end
end

# ------------------------------------------------------------
# Generate rules
# ------------------------------------------------------------

out = +""

fields.each do |field_name, field_def|
  rule_meta = field_def['_rule'] || raise("Felt #{field_name} mangler _rule metadata")
  domain    = rule_meta['domain']
  scope     = rule_meta['scope']
  
  mandatory = field_def['mandatory']
  next unless mandatory

  xpath = field_def.fetch('xpath')
  kind  = mandatory.fetch('kind')

  constraints = Array(mandatory.fetch('constraints'))

  constraints.each_with_index do |constraint, i|
    rationale = constraint.dig('_rationale', 'eng') || raise("Missing eng rationale for #{field_name}")

    # Vi sender XPathen inn til folding her. 
    # Siden YAML-nøkkelen 'test:' er rykket inn 4 mellomrom, 
    # bør verdien rykkes inn til f.eks. 6 for å være trygg.
    test_expr = YamlText.folded_lines(count_test(xpath, kind), indent: 6)

    # VIKTIG: #{test_expr} må stå helt til venstre i editoren din her
    # for at ikke <<~YAML skal legge på sine egne mellomrom i tillegg.
    out << <<~YAML
      #{field_name}:
        - id: #{rule_id(domain: domain, scope: scope, kind: kind.to_sym, index: i)}
          context: "/*"
          test: >-
      #{test_expr}
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
