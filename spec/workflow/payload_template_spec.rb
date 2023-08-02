RSpec.describe Floe::Workflow::PayloadTemplate do
  let(:subject) { described_class.new(payload) }

  describe "#value" do
    context "with static values" do
      let(:payload) { {"foo" => "bar", "bar" => "$.baz"} }
      let(:context) { {} }

      it "returns the original value" do
        expect(subject.value(context)).to eq({"foo" => "bar", "bar" => "$.baz"})
      end
    end

    context "with dynamic values" do
      let(:payload) { {"foo.$" => "$.foo", "bar.$" => "$$.bar"} }
      let(:context) { {"bar" => "baz"} }
      let(:inputs)  { {"foo" => "bar"} }

      it "returns the value from the inputs" do
        expect(subject.value(context, inputs)).to eq({"foo" => "bar", "bar" => "baz"})
      end
    end
  end
end
