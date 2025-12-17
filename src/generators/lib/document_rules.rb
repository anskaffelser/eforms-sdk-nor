#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

require_relative 'rule_index'
require_relative 'yaml_text_folder'

BASE = Pathname.new(__dir__).join('../../..').expand_path

POLICY_DIR = BASE.join('src/policy/national')

DOCUMENT_RULES = POLICY_DIR.join('document_rules.yaml')

OUT_PATH = BASE.join('src/generated/national/document.rules.fragment.yaml')

HEADER_PATH = POLICY_DIR.join("LICENSE_HEADER.fragment.txt")

policy_document_rules= YAML.load_file(DOCUMENT_RULES)

RuleIndex.validate!

# ------------------------------------------------------------
# Load and enrich header
# ------------------------------------------------------------

raw_header = File.read(HEADER_PATH)

header = raw_header.gsub('<FRAGMENT_FILENAME>', OUT_PATH.basename.to_s)

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

# ------------------------------------------------------------
# Generate rules
# ------------------------------------------------------------

out = +""


out << <<~YAML
ND-Root:
YAML

policy_document_rules.fetch('ND-Root').each_with_index do |(_name, spec), i|
  test = spec.fetch('test').strip
  message =
    spec
      .fetch('description')
      .fetch('eng')

  folded_test =
    YamlText.folded_lines(
      test,
      indent: 6
    )

  out << <<~YAML
  - id: #{rule_id(domain: 'DR', scope: 'global', kind: :consistency, index: i)}
    test: >-
#{folded_test}
    message: >-
      #{message}
  YAML
end


final_output = header + "---\n" + out

File.write(OUT_PATH, final_output)

puts "Wrote document rules fragment to:"
puts "  #{OUT_PATH}"
