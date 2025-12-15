#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

require_relative 'rule_index'
require_relative 'yaml_text_folder'

BASE = File.expand_path('../../..', __dir__)

POLICY_PATH =
  File.join(
    BASE,
    'src/policy/national/document_rules.yaml'
  )

OUT_PATH =
  File.join(
    BASE,
    'src/generated/national/document.rules.fragment.yaml'
  )

policy = YAML.load_file(POLICY_PATH)

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

# ------------------------------------------------------------
# Generate rules
# ------------------------------------------------------------

out = +""


out << <<~YAML
ND-Root:
YAML

policy.fetch('ND-Root').each_with_index do |(_name, spec), i|
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

File.write(OUT_PATH, out)

puts "Wrote document rules fragment to:"
puts "  #{OUT_PATH}"
