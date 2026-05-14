# frozen_string_literal: true

require "json"

module Vastlint
  class Issue
    attr_reader :id, :severity, :message, :path, :spec_ref, :line, :col

    def initialize(id:, severity:, message:, path:, spec_ref:, line:, col:)
      @id = id
      @severity = severity
      @message = message
      @path = path
      @spec_ref = spec_ref
      @line = line
      @col = col
    end

    def as_json(*)
      {
        id: id,
        severity: severity,
        message: message,
        path: path,
        spec_ref: spec_ref,
        line: line,
        col: col
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
