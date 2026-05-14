# frozen_string_literal: true

require "json"

module Vastlint
  class Result
    attr_reader :version, :issues, :summary

    def self.from_json(json_payload)
      parsed = JSON.parse(json_payload)

      new(
        version: parsed["version"],
        issues: Array(parsed["issues"]).map do |issue|
          Issue.new(
            id: issue["id"],
            severity: issue["severity"],
            message: issue["message"],
            path: issue["path"],
            spec_ref: issue["spec_ref"],
            line: issue["line"],
            col: issue["col"]
          )
        end,
        summary: Summary.new(
          errors: parsed.fetch("summary").fetch("errors"),
          warnings: parsed.fetch("summary").fetch("warnings"),
          infos: parsed.fetch("summary").fetch("infos"),
          valid: parsed.fetch("summary").fetch("valid")
        )
      )
    rescue JSON::ParserError => error
      raise LibraryError, "failed to parse vastlint result JSON: #{error.message}"
    end

    def initialize(version:, issues:, summary:)
      @version = version
      @issues = issues
      @summary = summary
    end

    def valid?
      summary.valid?
    end

    def as_json(*)
      {
        version: version,
        issues: issues.map(&:as_json),
        summary: summary.as_json
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
