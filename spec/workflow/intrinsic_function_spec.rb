RSpec.describe Floe::Workflow::IntrinsicFunction do
  describe ".evaluate" do
    describe "States.Array" do
      it "with a single value" do
        result = described_class.evaluate("States.Array(1)")
        expect(result).to eq([1])
      end

      it "with multiple values" do
        result = described_class.evaluate("States.Array(1, 2, 3)")
        expect(result).to eq([1, 2, 3])
      end

      it "with different types of args" do
        result = described_class.evaluate("States.Array('string', 1, 1.5, true, false, null, $.input)", {"input" => {"foo" => "bar"}})
        expect(result).to eq(["string", 1, 1.5, true, false, nil, {"foo" => "bar"}])
      end

      it "with jsonpath args" do
        result = described_class.evaluate("States.Array($.input)", {"input" => {"foo" => "bar"}})
        expect(result).to eq([{"foo" => "bar"}])
      end

      it "with nested States functions" do
        result = described_class.evaluate("States.Array(States.UUID(), States.UUID())")

        uuid_regex = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/
        expect(result).to match_array([a_string_matching(uuid_regex), a_string_matching(uuid_regex)])
      end
    end

    describe "States.UUID" do
      it "returns a v4 UUID" do
        result = described_class.evaluate("States.UUID()")

        match = result.match(/^\h{8}-\h{4}-(\h{4})-\h{4}-\h{12}$/)
        expect(match).to be

        uuid_version = match[1].to_i(16) >> 12
        expect(uuid_version).to eq(4)
      end
    end
  end
end
