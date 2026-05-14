# frozen_string_literal: true

require_relative "lib/vastlint/version"

Gem::Specification.new do |spec|
  spec.name = "vastlint"
  spec.version = Vastlint::VERSION
  spec.authors = ["Alex Sekowski"]
  spec.email = ["alex@vastlint.org"]

  spec.summary = "In-process Ruby bindings for vastlint VAST XML validation"
  spec.description = "Ruby bindings for the vastlint Rust core via the stable C FFI. Validate VAST XML in a DSP backend and return structured results directly to a React frontend."
  spec.homepage = "https://vastlint.org"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/aleksUIX/vastlint-ruby",
    "changelog_uri" => "https://github.com/aleksUIX/vastlint-ruby/releases",
    "documentation_uri" => "https://vastlint.org/docs/rules",
    "github_repo" => "ssh://github.com/aleksUIX/vastlint-ruby"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir[
      "Gemfile",
      "README.md",
      "Rakefile",
      "lib/**/*.rb",
      "lib/vastlint/native/**/*",
      "scripts/*",
      "test/**/*"
    ]
  end

  spec.bindir = "exe"
  spec.require_paths = ["lib"]
end
