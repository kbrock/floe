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
      it "with no values" do
        result = described_class.value("States.Array()")
        expect(result).to eq([])
      end

      it "with a single value" do
        result = described_class.value("States.Array(1)")
        expect(result).to eq([1])
      end

      it "with a single null value" do
        result = described_class.value("States.Array(null)")
        expect(result).to eq([nil])
      end

      it "with a single array value" do
        result = described_class.value("States.Array(States.Array())")
        expect(result).to eq([[]])
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

    describe "States.ArrayPartition" do
      it "with expected args" do
        result = described_class.value("States.ArrayPartition(States.Array(1, 2, 3, 4, 5, 6, 7, 8, 9), 4)")
        expect(result).to eq([[1, 2, 3, 4], [5, 6, 7, 8], [9]])
      end

      it "with an empty array" do
        result = described_class.value("States.ArrayPartition(States.Array(), 4)")
        expect(result).to eq([]) # This matches the stepfunctions simulator and is not [[]]
      end

      it "with chunk size larger than the array size" do
        result = described_class.value("States.ArrayPartition(States.Array(1, 2, 3), 4)")
        expect(result).to eq([[1, 2, 3]])
      end

      it "with jsonpath for the array" do
        result = described_class.value("States.ArrayPartition($.array, 4)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9]})
        expect(result).to eq([[1, 2, 3, 4], [5, 6, 7, 8], [9]])
      end

      it "with jsonpath for the array and chunk size" do
        result = described_class.value("States.ArrayPartition($.array, $.chunk)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9], "chunk" => 4})
        expect(result).to eq([[1, 2, 3, 4], [5, 6, 7, 8], [9]])
      end

      it "fails with invalid args" do
        expect { described_class.value("States.ArrayPartition()") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayPartition (given 0, expected 2)")
        expect { described_class.value("States.ArrayPartition(1)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayPartition (given 1, expected 2)")
        expect { described_class.value("States.ArrayPartition(States.Array(), 1, 'foo')") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayPartition (given 3, expected 2)")

        expect { described_class.value("States.ArrayPartition(1, 4)") }.to raise_error(ArgumentError, "wrong type for argument 1 to States.ArrayPartition (given Integer, expected Array)")
        expect { described_class.value("States.ArrayPartition(States.Array(), 'foo')") }.to raise_error(ArgumentError, "wrong type for argument 2 to States.ArrayPartition (given String, expected Integer)")

        expect { described_class.value("States.ArrayPartition(States.Array(), -1)") }.to raise_error(ArgumentError, "invalid value for argument 2 to States.ArrayPartition (given -1, expected a positive Integer)")
        expect { described_class.value("States.ArrayPartition(States.Array(), 0)") }.to raise_error(ArgumentError, "invalid value for argument 2 to States.ArrayPartition (given 0, expected a positive Integer)")
      end
    end

    describe "States.ArrayContains" do
      # NOTE: The stepfunctions simulator fails with States.Array() passed as a parameter, but we support it

      it "with an array containing the target value" do
        result = described_class.value("States.ArrayContains(States.Array(1, 2, 3, 4, 5, 6, 7, 8, 9), 5)")
        expect(result).to eq(true)
      end

      it "with an array missing the target value" do
        result = described_class.value("States.ArrayContains(States.Array(1, 2, 3), 5)")
        expect(result).to eq(false)
      end

      it "with an empty array" do
        result = described_class.value("States.ArrayContains(States.Array(), 5)")
        expect(result).to eq(false)
      end

      it "with jsonpath for the array" do
        result = described_class.value("States.ArrayContains($.array, 5)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9]})
        expect(result).to eq(true)
      end

      it "with jsonpath for the array and target value" do
        result = described_class.value("States.ArrayContains($.array, $.target)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9], "target" => 5})
        expect(result).to eq(true)
      end

      it "with string values in the array" do
        result = described_class.value("States.ArrayContains($.array, '5')", {}, {"array" => %w[1 2 3 4 5 6 7 8 9]})
        expect(result).to eq(true)
      end

      it "with string values in the array but an integer target value" do
        result = described_class.value("States.ArrayContains($.array, 5)", {}, {"array" => %w[1 2 3 4 5 6 7 8 9]})
        expect(result).to eq(false)
      end

      it "fails with invalid args" do
        expect { described_class.value("States.ArrayContains()") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayContains (given 0, expected 2)")
        expect { described_class.value("States.ArrayContains(1)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayContains (given 1, expected 2)")
        expect { described_class.value("States.ArrayContains(States.Array(), 1, 'foo')") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayContains (given 3, expected 2)")

        expect { described_class.value("States.ArrayContains(1, 5)") }.to raise_error(ArgumentError, "wrong type for argument 1 to States.ArrayContains (given Integer, expected Array)")
      end
    end

    describe "States.ArrayRange" do
      it "with a positive ascending range, incrementing" do
        result = described_class.value("States.ArrayRange(1, 9, 2)")
        expect(result).to eq([1, 3, 5, 7, 9])
      end

      it "with a spanning ascending range, incrementing" do
        result = described_class.value("States.ArrayRange(-1, 9, 2)")
        expect(result).to eq([-1, 1, 3, 5, 7, 9])
      end

      it "with a negative ascending range, incrementing" do
        result = described_class.value("States.ArrayRange(-9, -1, 2)")
        expect(result).to eq([-9, -7, -5, -3, -1])
      end

      it "with a postive descending range, decrementing" do
        result = described_class.value("States.ArrayRange(9, 1, -2)")
        expect(result).to eq([9, 7, 5, 3, 1])
      end

      it "with a spanning descending range, decrementing" do
        result = described_class.value("States.ArrayRange(9, -1, -2)")
        expect(result).to eq([9, 7, 5, 3, 1, -1])
      end

      it "with a negative descending range, decrementing" do
        result = described_class.value("States.ArrayRange(-1, -9, -2)")
        expect(result).to eq([-1, -3, -5, -7, -9])
      end

      it "with a positive ascending range, decrementing" do
        result = described_class.value("States.ArrayRange(1, 9, -2)")
        expect(result).to eq([])
      end

      it "with a negative ascending range, decrementing" do
        result = described_class.value("States.ArrayRange(-9, -1, -2)")
        expect(result).to eq([])
      end

      it "with a positive descending range, incrementing" do
        result = described_class.value("States.ArrayRange(9, 1, 2)")
        expect(result).to eq([])
      end

      it "with a negative descending range, incrementing" do
        result = described_class.value("States.ArrayRange(-1, -9, 2)")
        expect(result).to eq([])
      end

      it "with jsonpath for the range start, range end, and increment" do
        result = described_class.value("States.ArrayRange($.start, $.end, $.increment)", {}, {"start" => 1, "end" => 9, "increment" => 2})
        expect(result).to eq([1, 3, 5, 7, 9])
      end

      it "with an increment that doesn't land evenly" do
        result = described_class.value("States.ArrayRange(1, 9, 3)")
        expect(result).to eq([1, 4, 7])
      end

      it "fails with invalid args" do
        expect { described_class.value("States.ArrayRange()") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayRange (given 0, expected 3)")
        expect { described_class.value("States.ArrayRange(1)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayRange (given 1, expected 3)")
        expect { described_class.value("States.ArrayRange(1, 9)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayRange (given 2, expected 3)")
        expect { described_class.value("States.ArrayRange(1, 9, 2, 4)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayRange (given 4, expected 3)")

        expect { described_class.value("States.ArrayRange('1', '9', '2')") }.to raise_error(ArgumentError, "wrong type for argument 1 to States.ArrayRange (given String, expected Integer)")
        expect { described_class.value("States.ArrayRange('1', 9, 2)") }.to raise_error(ArgumentError, "wrong type for argument 1 to States.ArrayRange (given String, expected Integer)")
        expect { described_class.value("States.ArrayRange(1, '9', 2)") }.to raise_error(ArgumentError, "wrong type for argument 2 to States.ArrayRange (given String, expected Integer)")
        expect { described_class.value("States.ArrayRange(1, 9, '2')") }.to raise_error(ArgumentError, "wrong type for argument 3 to States.ArrayRange (given String, expected Integer)")

        expect { described_class.value("States.ArrayRange(1, 9, 0)") }.to raise_error(ArgumentError, "invalid value for argument 3 to States.ArrayRange (given 0, expected a non-zero Integer)")
      end
    end

    describe "States.ArrayGetItem" do
      # NOTE: The stepfunctions simulator fails with States.Array() passed as a parameter, but we support it

      it "with an index in range" do
        result = described_class.value("States.ArrayGetItem(States.Array(1, 2, 3, 4, 5, 6, 7, 8, 9), 5)")
        expect(result).to eq(6)
      end

      it "with an index out of range" do
        result = described_class.value("States.ArrayGetItem(States.Array(1, 2, 3), 5)")
        expect(result).to eq(nil)
      end

      it "with an empty array" do
        result = described_class.value("States.ArrayGetItem(States.Array(), 5)")
        expect(result).to eq(nil)
      end

      it "with jsonpath for the array" do
        result = described_class.value("States.ArrayGetItem($.array, 5)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9]})
        expect(result).to eq(6)
      end

      it "with jsonpath for the array and index" do
        result = described_class.value("States.ArrayGetItem($.array, $.index)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9], "index" => 5})
        expect(result).to eq(6)
      end

      it "fails with invalid args" do
        expect { described_class.value("States.ArrayGetItem()") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayGetItem (given 0, expected 2)")
        expect { described_class.value("States.ArrayGetItem(1)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayGetItem (given 1, expected 2)")
        expect { described_class.value("States.ArrayGetItem(States.Array(), 1, 'foo')") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayGetItem (given 3, expected 2)")

        expect { described_class.value("States.ArrayGetItem(States.Array(), '5')") }.to raise_error(ArgumentError, "wrong type for argument 2 to States.ArrayGetItem (given String, expected Integer)")

        expect { described_class.value("States.ArrayGetItem(States.Array(), -1)") }.to raise_error(ArgumentError, "invalid value for argument 2 to States.ArrayGetItem (given -1, expected 0 or a positive Integer)")
      end
    end

    describe "States.ArrayLength" do
      # NOTE: The stepfunctions simulator fails with States.Array() passed as a parameter, but we support it

      it "with an array" do
        result = described_class.value("States.ArrayLength(States.Array(1, 2, 3, 4, 5, 6, 7, 8, 9))")
        expect(result).to eq(9)
      end

      it "with an empty array" do
        result = described_class.value("States.ArrayLength(States.Array())")
        expect(result).to eq(0)
      end

      it "with jsonpath for the array" do
        result = described_class.value("States.ArrayLength($.array)", {}, {"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9]})
        expect(result).to eq(9)
      end

      it "fails with invalid args" do
        expect { described_class.value("States.ArrayLength()") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayLength (given 0, expected 1)")
        expect { described_class.value("States.ArrayLength(States.Array(), 1)") }.to raise_error(ArgumentError, "wrong number of arguments to States.ArrayLength (given 2, expected 1)")

        expect { described_class.value("States.ArrayLength(1)") }.to raise_error(ArgumentError, "wrong type for argument 1 to States.ArrayLength (given Integer, expected Array)")
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

      it "fails with invalid args" do
        expect { described_class.value("States.UUID(1)") }.to raise_error(ArgumentError, "wrong number of arguments to States.UUID (given 1, expected 0)")
        expect { described_class.value("States.UUID(null)") }.to raise_error(ArgumentError, "wrong number of arguments to States.UUID (given 1, expected 0)")
        expect { described_class.value("States.UUID(1, 2)") }.to raise_error(ArgumentError, "wrong number of arguments to States.UUID (given 2, expected 0)")
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
        expect { described_class.value("States.Array") }.to raise_error(Floe::InvalidWorkflowError, /Expected one of \[[A-Z_, ]+\] at line 1 char 1./)
      end

      it "does not parse missing closing paren" do
        expect { described_class.value("States.Array(1, ") }.to raise_error(Floe::InvalidWorkflowError, /Expected one of \[[A-Z_, ]+\] at line 1 char 1./)
      end

      it "does not parse trailing commas in args" do
        expect { described_class.value("States.Array(1,)") }.to raise_error(Floe::InvalidWorkflowError, /Expected one of \[[A-Z_, ]+\] at line 1 char 1./)
      end

      it "keeps the parslet error as the cause" do
        error = described_class.value("States.Array") rescue $! # rubocop:disable Style/RescueModifier, Style/SpecialGlobalVars
        expect(error.cause).to be_a(Parslet::ParseFailed)
      end
    end
  end
end
