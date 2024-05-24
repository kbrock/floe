# Ignore percent-delimeter cop because our test Strings can have all kinds of
#   characters and using `%q||` keeps the tests consistent, even if it's not
#   needed.
# rubocop:disable Style/PercentLiteralDelimiters, Style/RedundantPercentQ

require 'parslet/rig/rspec'

RSpec.describe Floe::Workflow::IntrinsicFunction::Parser do
  describe "spaces" do
    subject { described_class.new.spaces }

    it do
      expect(subject).to parse(" ")
      expect(subject).to parse("  ")
      expect(subject).to parse("   ")

      expect(subject).to_not parse("")
      expect(subject).to_not parse("\t")
      expect(subject).to_not parse("a")
    end
  end

  describe "spaces?" do
    subject { described_class.new.spaces? }

    it do
      expect(subject).to parse(" ")
      expect(subject).to parse("  ")
      expect(subject).to parse("   ")
      expect(subject).to parse("")

      expect(subject).to_not parse("\t")
      expect(subject).to_not parse("\n")
    end
  end

  describe "comma_sep" do
    subject { described_class.new.comma_sep }

    it do
      expect(subject).to parse(",")
      expect(subject).to parse(", ")
      expect(subject).to parse(",  ")
    end
  end

  describe "number" do
    subject { described_class.new.number }

    it do
      expect(subject).to parse("0")
      expect(subject).to parse("1")
      expect(subject).to parse("123")

      expect(subject).to parse("-0")
      expect(subject).to parse("-1")
      expect(subject).to parse("-123")

      expect(subject).to parse("0e1")
      expect(subject).to parse("1e1")
      expect(subject).to parse("123e1")
      expect(subject).to parse("123e123")
      expect(subject).to parse("123e-1")
      expect(subject).to parse("123e-123")

      expect(subject).to parse("-0e1")
      expect(subject).to parse("-1e1")
      expect(subject).to parse("-123e1")
      expect(subject).to parse("-123e123")
      expect(subject).to parse("-123e-1")
      expect(subject).to parse("-123e-123")

      expect(subject).to parse("0.0")
      expect(subject).to parse("0.01")
      expect(subject).to parse("1.0")
      expect(subject).to parse("1.01")
      expect(subject).to parse("123.123")

      expect(subject).to parse("-0.0")
      expect(subject).to parse("-0.01")
      expect(subject).to parse("-1.0")
      expect(subject).to parse("-1.01")
      expect(subject).to parse("-123.123")

      expect(subject).to parse("0.0e1")
      expect(subject).to parse("0.0e123")
      expect(subject).to parse("0.01e1")
      expect(subject).to parse("0.01e123")
      expect(subject).to parse("123.123e1")
      expect(subject).to parse("123.123e123")
      expect(subject).to parse("123.123e-1")
      expect(subject).to parse("123.123e-123")

      expect(subject).to parse("-0.0e1")
      expect(subject).to parse("-0.0e123")
      expect(subject).to parse("-0.01e1")
      expect(subject).to parse("-0.01e123")
      expect(subject).to parse("-123.123e1")
      expect(subject).to parse("-123.123e123")
      expect(subject).to parse("-123.123e-1")
      expect(subject).to parse("-123.123e-123")

      expect(subject).to_not parse(".")
      expect(subject).to_not parse(".1")
      expect(subject).to_not parse("1.")
      expect(subject).to_not parse("-1.")
      expect(subject).to_not parse("1..2")
      expect(subject).to_not parse("1.e1")
      expect(subject).to_not parse("-1.e1")
      expect(subject).to_not parse("01")
      expect(subject).to_not parse("1e")
      expect(subject).to_not parse("e")
      expect(subject).to_not parse("e123")
    end
  end

  describe "string" do
    subject { described_class.new.string }

    it do
      expect(subject).to parse(%q|''|)
      expect(subject).to parse(%q|'str'|)
      expect(subject).to parse(%q|'str\'str'|)
      expect(subject).to parse(%q|'str\\\\str'|)

      expect(subject).to_not parse("str")
      expect(subject).to_not parse("'str")
      expect(subject).to_not parse("str'")
      expect(subject).to_not parse("'str'str'")

      # TODO: Many more test cases
    end
  end

  describe "arg" do
    subject { described_class.new.arg }

    it do
      expect(subject).to parse(%q|'str'|)
      expect(subject).to parse("123")
      expect(subject).to parse("true")
      expect(subject).to parse("false")
      expect(subject).to parse("null")
    end
  end

  describe "args" do
    subject { described_class.new.args }

    it do
      expect(subject).to parse(%q|'str'|)
      expect(subject).to parse(%q|'str', 123|)
      expect(subject).to parse(%q|'str', 123, true, false, null|)
      expect(subject).to parse(%q|'str',   123,true|)
    end
  end

  describe "states_array" do
    subject { described_class.new.states_array }

    it do
      expect(subject).to parse(%q|States.Array('str')|)
      expect(subject).to parse(%q|States.Array('str', 123)|)
      expect(subject).to parse(%q|States.Array('str', 123, true, false, null)|)
      expect(subject).to parse(%q|States.Array('str',   123,true)|)
    end
  end
end

# rubocop:enable Style/PercentLiteralDelimiters, Style/RedundantPercentQ
