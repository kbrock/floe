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
        result = described_class.evaluate("States.Array('string', 1, 1.5, true, false, null)")
        expect(result).to eq(["string", 1, 1.5, true, false, nil])
      end

      it "with jsonpath args" do
        pending("jsonpath not yet implemented")

        result = described_class.evaluate("States.Array($.input)", {"input" => {"foo" => "bar"}})
        expect(result).to eq([{"foo" => "bar"}])
      end
    end
  end
end
