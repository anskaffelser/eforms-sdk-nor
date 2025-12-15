# frozen_string_literal: true

require 'yaml'

module RuleIndex
  BASE = File.expand_path('../../..', __dir__)

  RULE_INDEX_PATH =
    File.join(
      BASE,
      'src/policy/national/rule_index.yaml'
    )

  INDEX = YAML.load_file(RULE_INDEX_PATH).freeze

  # ------------------------------------------------------------
  # Public API
  # ------------------------------------------------------------

  def self.group(domain:, kind:, scope: 'global')
    domain_map = INDEX.fetch(domain.to_s) do
      raise KeyError, "Unknown rule domain: #{domain.inspect}"
    end

    scope_map = domain_map.fetch(scope.to_s) do
      raise KeyError,
            "Unknown scope #{scope.inspect} for domain #{domain.inspect}"
    end

    scope_map.fetch(kind.to_s) do
      raise KeyError,
            "Unknown rule kind #{kind.inspect} for domain #{domain.inspect} / scope #{scope.inspect}"
    end
  end

  # ------------------------------------------------------------
  # Validation
  # ------------------------------------------------------------

  def self.validate!
    INDEX.each do |domain, scopes|
      raise "RuleIndex domain must be String" unless domain.is_a?(String)
      raise "RuleIndex scopes must be mapping" unless scopes.is_a?(Hash)

      scopes.each do |scope, kinds|
        raise "Scope must be String" unless scope.is_a?(String)
        raise "Kinds must be mapping" unless kinds.is_a?(Hash)

        kinds.each do |kind, group|
          raise "Kind must be String" unless kind.is_a?(String)
          raise "Group must be Integer" unless group.is_a?(Integer)
        end
      end
    end
    true
  end
end
