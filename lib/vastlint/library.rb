# frozen_string_literal: true

require "fiddle"
require "fiddle/import"
require "json"
require "rbconfig"
require "singleton"

module Vastlint
  class Library
    include Singleton

    def validate(xml, wrapper_depth:, max_wrapper_depth:, rule_overrides:)
      raw_result = if default_call?(wrapper_depth, max_wrapper_depth, rule_overrides)
        api.vastlint_validate(xml, xml.bytesize)
      else
        api.vastlint_validate_with_options(
          xml,
          xml.bytesize,
          wrapper_depth,
          max_wrapper_depth,
          serialize_rule_overrides(rule_overrides)
        )
      end

      raise LibraryError, "vastlint returned NULL" if null_pointer?(raw_result)

      begin
        json_payload = read_c_string(api.vastlint_result_json(raw_result))
        raise LibraryError, "vastlint_result_json returned NULL" if json_payload.nil? || json_payload.empty?

        json_payload
      ensure
        api.vastlint_result_free(raw_result) unless null_pointer?(raw_result)
      end
    end

    def version
      read_c_string(api.vastlint_version()) || raise(LibraryError, "vastlint_version returned NULL")
    end

    def path
      self.class.resolve_path
    end

    class << self
      def resolve_path
        candidates = [ENV["VASTLINT_LIB_PATH"], vendored_path, *development_paths].compact
        match = candidates.find { |candidate| File.file?(candidate) }
        return match if match

        raise LibraryError, <<~MESSAGE.strip
          unable to find libvastlint for #{platform_label}
          looked in:
          #{candidates.map { |candidate| "  - #{candidate}" }.join("\n")}
          set VASTLINT_LIB_PATH or vendor a release library under lib/vastlint/native
        MESSAGE
      end

      private

      def vendored_path
        File.join(repo_root, "lib", "vastlint", "native", platform_directory, library_filename)
      end

      def development_paths
        sibling_vastlint_root = File.expand_path("../vastlint", repo_root)
        extension = shared_library_extension

        [
          File.join(sibling_vastlint_root, "target", "debug", "libvastlint_ffi.#{extension}"),
          File.join(sibling_vastlint_root, "target", "release", "libvastlint_ffi.#{extension}")
        ]
      end

      def repo_root
        File.expand_path("../..", __dir__)
      end

      def library_filename
        "libvastlint.#{shared_library_extension}"
      end

      def shared_library_extension
        macos? ? "dylib" : "so"
      end

      def platform_directory
        cpu = RbConfig::CONFIG.fetch("host_cpu")

        if macos?
          return "darwin_arm64" if cpu.match?(/arm64|aarch64/)
          return "darwin_amd64" if cpu.match?(/x86_64|amd64/)
        elsif linux?
          return "linux_arm64" if cpu.match?(/arm64|aarch64/)
          return "linux_amd64" if cpu.match?(/x86_64|amd64/)
        end

        raise LibraryError, "unsupported platform #{platform_label}"
      end

      def platform_label
        "#{RbConfig::CONFIG.fetch("host_os")}/#{RbConfig::CONFIG.fetch("host_cpu")}"
      end

      def macos?
        RbConfig::CONFIG.fetch("host_os").include?("darwin")
      end

      def linux?
        RbConfig::CONFIG.fetch("host_os").include?("linux")
      end
    end

    private

    def api
      @api ||= begin
        library_path = self.class.resolve_path

        Module.new.tap do |mod|
          mod.extend(Fiddle::Importer)
          mod.dlload(library_path)
          mod.extern "void* vastlint_validate(const char*, size_t)"
          mod.extern "void* vastlint_validate_with_options(const char*, size_t, unsigned int, unsigned int, const char*)"
          mod.extern "char* vastlint_result_json(void*)"
          mod.extern "void vastlint_result_free(void*)"
          mod.extern "char* vastlint_version()"
        end
      rescue Fiddle::DLError => error
        raise LibraryError, "failed to load #{library_path}: #{error.message}"
      end
    end

    def default_call?(wrapper_depth, max_wrapper_depth, rule_overrides)
      wrapper_depth.zero? && max_wrapper_depth == 5 && (rule_overrides.nil? || rule_overrides.empty?)
    end

    def serialize_rule_overrides(rule_overrides)
      return nil if rule_overrides.nil? || rule_overrides.empty?

      JSON.generate(rule_overrides)
    end

    def null_pointer?(pointer)
      pointer.nil? || pointer.to_i.zero?
    end

    def read_c_string(value)
      case value
      when nil
        nil
      when String
        value
      else
        Fiddle::Pointer.new(value.to_i).to_s
      end
    end
  end
end
