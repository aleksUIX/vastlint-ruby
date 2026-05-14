# frozen_string_literal: true

require_relative "vastlint/version"
require_relative "vastlint/error"
require_relative "vastlint/library"
require_relative "vastlint/issue"
require_relative "vastlint/summary"
require_relative "vastlint/result"

module Vastlint
  class << self
    def validate(xml, wrapper_depth: 0, max_wrapper_depth: 5, rule_overrides: nil)
      normalized_xml = normalize_xml(xml)
      validate_options!(wrapper_depth, max_wrapper_depth, rule_overrides)

      Result.from_json(
        Library.instance.validate(
          normalized_xml,
          wrapper_depth: wrapper_depth,
          max_wrapper_depth: max_wrapper_depth,
          rule_overrides: rule_overrides
        )
      )
    end

    def version
      Library.instance.version
    end

    private

    def normalize_xml(xml)
      raise ArgumentError, "xml must be a String" unless xml.is_a?(String)
      raise ArgumentError, "xml must not be empty" if xml.empty?

      xml
    end

    def validate_options!(wrapper_depth, max_wrapper_depth, rule_overrides)
      unless wrapper_depth.is_a?(Integer) && wrapper_depth >= 0
        raise ArgumentError, "wrapper_depth must be an Integer >= 0"
      end

      unless max_wrapper_depth.is_a?(Integer) && max_wrapper_depth >= 0
        raise ArgumentError, "max_wrapper_depth must be an Integer >= 0"
      end

      return if rule_overrides.nil? || rule_overrides.is_a?(Hash)

      raise ArgumentError, "rule_overrides must be a Hash or nil"
    end
  end
end
