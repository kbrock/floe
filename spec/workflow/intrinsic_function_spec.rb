RSpec.describe Floe::Workflow::IntrinsicFunction do
  describe ".intrinsic_function?" do
    context "with an intrinsic function" do
      it "returns true" do
        expect(described_class.intrinsic_function?("States.Array(1)")).to be_truthy
      end
    end

    context "with a Path" do
      it "returns false" do
        expect(described_class.intrinsic_function?("$.foo")).to be_falsey
      end
    end

    context "with a string" do
      it "returns false" do
        expect(described_class.intrinsic_function?("foo")).to be_falsey
      end
    end
  end

  describe ".value" do
    describe "States.Array" do
      it "with a single value" do
        result = described_class.value("States.Array(1)")
        expect(result).to eq([1])
      end

      it "with multiple values" do
        result = described_class.value("States.Array(1, 2, 3)")
        expect(result).to eq([1, 2, 3])
      end

      it "with different types of args" do
        result = described_class.value("States.Array('string', 1, 1.5, true, false, null, $.input)", {}, {"input" => {"foo" => "bar"}})
        expect(result).to eq(["string", 1, 1.5, true, false, nil, {"foo" => "bar"}])
      end

      it "with nested States functions" do
        result = described_class.value("States.Array(States.UUID(), States.UUID())")

        uuid_regex = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/
        expect(result).to match_array([a_string_matching(uuid_regex), a_string_matching(uuid_regex)])
      end
    end

    describe "States.UUID" do
      it "returns a v4 UUID" do
        result = described_class.value("States.UUID()")

        match = result.match(/^\h{8}-\h{4}-(\h{4})-\h{4}-\h{12}$/)
        expect(match).to be

        uuid_version = match[1].to_i(16) >> 12
        expect(uuid_version).to eq(4)
      end
    end

    describe "with jsonpath args" do
      it "fetches values from the input" do
        result = described_class.value("States.Array($.input)", {"context" => {"baz" => "qux"}}, {"input" => {"foo" => "bar"}})
        expect(result).to eq([{"foo" => "bar"}])
      end

      it "fetches values from the context" do
        result = described_class.value("States.Array($$.context)", {"context" => {"baz" => "qux"}}, {"input" => {"foo" => "bar"}})
        expect(result).to eq([{"baz" => "qux"}])
      end

      it "can return the entire input" do
        result = described_class.value("States.Array($)", {"context" => {"baz" => "qux"}}, {"input" => {"foo" => "bar"}})
        expect(result).to eq([{"input" => {"foo" => "bar"}}])
      end

      it "can return the entire context" do
        result = described_class.value("States.Array($$)", {"context" => {"baz" => "qux"}}, {"input" => {"foo" => "bar"}})
        expect(result).to eq([{"context" => {"baz" => "qux"}}])
      end

      it "fetches deep values" do
        result = described_class.value("States.Array($.input.foo)", {"context" => {"baz" => "qux"}}, {"input" => {"foo" => "bar"}})
        expect(result).to eq(["bar"])
      end

      it "handles invalid path references" do
        result = described_class.value("States.Array($.xxx)", {"context" => {"baz" => "qux"}}, {"input" => {"foo" => "bar"}})
        expect(result).to eq([nil])
      end
    end

    describe "with parsing errors" do
      it "does not parse missing parens" do
        expect { described_class.value("States.UUID") }.to raise_error(Floe::InvalidWorkflowError, /Expected one of \[[A-Z_, ]+\] at line 1 char 1./)
      end

      it "does not parse missing closing paren" do
        expect { described_class.value("States.Array(1, ") }.to raise_error(Floe::InvalidWorkflowError, /Expected one of \[[A-Z_, ]+\] at line 1 char 1./)
      end

      it "does not parse trailing commas in args" do
        expect { described_class.value("States.Array(1,)") }.to raise_error(Floe::InvalidWorkflowError, /Expected one of \[[A-Z_, ]+\] at line 1 char 1./)
      end

      it "keeps the parslet error as the cause" do
        error = described_class.value("States.UUID") rescue $! # rubocop:disable Style/RescueModifier, Style/SpecialGlobalVars
        expect(error.cause).to be_a(Parslet::ParseFailed)
      end
    end
  end
end
