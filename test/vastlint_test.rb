# frozen_string_literal: true

require_relative "test_helper"

class VastlintTest < Minitest::Test
  def test_version_returns_a_string
    refute_empty Vastlint.version
  end

  def test_valid_fixture_returns_no_errors
    result = Vastlint.validate(read_fixture("valid.xml"))

    assert result.valid?
    assert_equal 0, result.summary.errors
    assert_equal true, result.summary.valid?
    assert_equal "2.0", result.version
  end

  def test_invalid_fixture_returns_structured_issues
    result = Vastlint.validate(read_fixture("invalid.xml"))

    refute result.valid?
    assert_operator result.summary.errors, :>, 0
    assert_operator result.issues.length, :>, 0
    assert_includes %w[error warning info], result.issues.first.severity
    assert_kind_of Hash, result.as_json
  end

  private

  def read_fixture(name)
    File.read(File.expand_path("fixtures/#{name}", __dir__))
  end
end
