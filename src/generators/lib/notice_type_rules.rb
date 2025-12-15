#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

require_relative 'rule_index'
require_relative 'yaml_text_folder'

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

BASE = File.expand_path('../../..', __dir__)

NOTICE_TYPES_PATH =
  File.join(
    BASE,
    'src/policy/national/notice_types.yaml'
  )

OUT_PATH =
  File.join(
    BASE,
    'src/generated/national/notice-type.rules.fragment.yaml'
  )

# ------------------------------------------------------------
# Load policy
# ------------------------------------------------------------

notice_types_def =
  YAML.load_file(NOTICE_TYPES_PATH)

notice_types =
  notice_types_def.keys.sort

puts "Loaded #{notice_types.size} national notice types"

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

# ------------------------------------------------------------
# Generate rule fragment
# ------------------------------------------------------------

def english_or_list(items)
  case items.length
  when 0
    ''
  when 1
    items.first
  when 2
    items.join(' or ')
  else
    "#{items[0..-2].join(', ')}, or #{items.last}"
  end
end


out = +""

out << <<~YAML
OPP-070-notice:
  - id: #{rule_id(domain: 'NT', scope: 'global', kind: :whitelist, index: 0)}
    test: >-
      normalize-space() = (
#{notice_types.map { |nt| "        '#{nt}'" }.join(",\n")}
      )
    message: >-
      Notice type must be #{english_or_list(notice_types)}.

YAML

# ------------------------------------------------------------
# Write output
# ------------------------------------------------------------

File.write(OUT_PATH, out)

puts "Wrote notice type rules fragment to:"
puts "  #{OUT_PATH}"
