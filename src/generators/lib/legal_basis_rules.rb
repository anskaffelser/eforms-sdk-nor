#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

require_relative 'rule_index'
require_relative 'yaml_text_folder'

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

BASE = File.expand_path('../../..', __dir__)

INTERMEDIATE_PATH =
  File.join(
    BASE,
    'src/generated/national/legal-basis.intermediate.yaml'
  )


OUT_PATH =
  File.join(
    BASE,
    'src/generated/national/legal-basis.rules.fragment.yaml'
  )

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

def rule_id(domain:, kind:, index:, scope: 'global')
  group = RuleIndex.group(domain: domain, scope: scope, kind: kind)
  suffix = alpha_index(index)

  format(
    "EFORMS-NOR-NATIONAL-%s-R%03d%s",
    domain,
    group,
    suffix
  )
end

# ------------------------------------------------------------
# Load intermediate
# ------------------------------------------------------------

data = YAML.load_file(INTERMEDIATE_PATH)

legal_basis =
  data
    .fetch('legal_basis')
    .map do |lb|
      {
        code:   lb.fetch('code'),
        e_text: lb.fetch('e_text').strip,
        f_text: lb.fetch('f_text').strip
      }
    end
    .sort_by { |lb| lb[:code] }

puts "Loaded #{legal_basis.size} legal basis entries"

# ------------------------------------------------------------
# Validate rule index
# ------------------------------------------------------------

RuleIndex.validate!

# ------------------------------------------------------------
# Generate YAML fragments
# ------------------------------------------------------------

out = +""

# ------------------------------------------------------------
# BT-01(e)-Procedure – whitelist
# ------------------------------------------------------------

out << <<~YAML
BT-01(e)-Procedure:
  - id: #{rule_id(domain: 'LB', kind: :whitelist, index: 0, scope: :name)}
    context: >-
      /*/cac:TenderingTerms
        /cac:ProcurementLegislationDocumentReference
        /cbc:ID
    test: >-
      normalize-space(.) = (
#{legal_basis.map { |lb| "        '#{lb[:e_text]}'" }.join(",\n")}
      )
    message: >-
      Local legal basis must be one of the recognised Norwegian procurement
      regulations

YAML

# ------------------------------------------------------------
# BT-01(f)-Procedure – pairwise rules
# ------------------------------------------------------------


out << <<~YAML
BT-01(f)-Procedure:
YAML

legal_basis.each_with_index do |lb, i|
  folded_f_text = YamlText.folded_lines(
    lb[:f_text],
    indent: 10  
  )

  message_text = 
    "When BT-01(e)-Procedure equals '#{lb[:e_text]}', " \
    "BT-01(f)-Procedure must contain its accompanying legend."

  folded_message = 
    YamlText.folded_lines(
      message_text,
      indent: 6
    )
  
  out << <<~YAML
  - id: #{rule_id(domain: 'LB', kind: :pairwise, index: i, scope: :description)}
    context: >-
      /*/cac:TenderingTerms
        /cac:ProcurementLegislationDocumentReference
        /cbc:DocumentDescription
    test: >-
      not(
        normalize-space(
          ../cbc:ID
        ) = '#{lb[:e_text]}'
      )
      or
      normalize-space(.) =
        normalize-space('
#{folded_f_text}
        ')
    message: >-
#{folded_message}
  YAML
end

# ------------------------------------------------------------
# Write output
# ------------------------------------------------------------

File.write(OUT_PATH, out)

puts "Wrote rules fragment to:"
puts "  #{OUT_PATH}"
