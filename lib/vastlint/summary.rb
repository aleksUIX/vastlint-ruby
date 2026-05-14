# frozen_string_literal: true

require "json"

module Vastlint
  class Summary
    attr_reader :errors, :warnings, :infos

    def initialize(errors:, warnings:, infos:, valid:)
      @errors = errors
      @warnings = warnings
      @infos = infos
      @valid = valid
    end

    def valid?
      @valid
    end

    def as_json(*)
      {
        errors: errors,
        warnings: warnings,
        infos: infos,
        valid: valid?
      }
    end

    def to_h
      as_json
    end

    def to_json(*args)
      JSON.generate(as_json, *args)
    end
  end
end
