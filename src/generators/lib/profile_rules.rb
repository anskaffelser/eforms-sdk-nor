#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require_relative 'rule_index'
require_relative 'yaml_text_folder'

BASE = File.expand_path('../../..', __dir__)

PROFILES_PATH =
  File.join(BASE, 'src/policy/national/profiles.yaml')

OUT_PATH =
  File.join(
    BASE,
    'src/generated/national/profile.rules.fragment.yaml'
  )

profiles = YAML.load_file(PROFILES_PATH)

out = +""

profiles.each do |profile_name, profile|
  cid = profile.fetch('customization_id')

  field   = cid.fetch('field')
  pattern = cid.fetch('pattern')

  rule_id =
    format(
      "EFORMS-NOR-NATIONAL-PI-R%03d",
      RuleIndex.group(domain: 'PI', kind: :profile, scope: 'global')
    )

  out << <<~YAML
  #{field}:
    - id: #{rule_id}
      test: >-
        matches(
          normalize-space(),
          '#{pattern}'
        )
      message: >-
        Customization identifier must match the Norwegian accepted identifier

  YAML
end

File.write(OUT_PATH, out)

puts "Generated profile rules:"
puts "  #{OUT_PATH}"
