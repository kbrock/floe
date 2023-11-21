RSpec.describe Floe::Workflow::ReferencePath do
  describe "#initialize" do
    context "with invalid value" do
      it "raises an exception" do
        expect { described_class.new("$.foo@.bar") }.to raise_error(Floe::InvalidWorkflowError, "Invalid Reference Path")
      end
    end
  end

  describe "#set" do
    let(:payload) { "$" }
    let(:subject) { described_class.new(payload) }
    let(:input) { {} }

    context "with a simple path" do
      it "sets the output at the top-level" do
        expect(subject.set(input, "foo" => "bar")).to eq("foo" => "bar")
      end
    end

    context "with a nested path" do
      let(:payload) { "$.nested.hash" }

      it "sets the output at the correct nested level" do
        expect(subject.set(input, "foo" => "bar")).to eq("nested" => {"hash" => {"foo" => "bar"}})
      end
    end

    context "with an array" do
      let(:input)   { {"master" => [{"foo" => "bar"}, {"bar" => "baz"}]} }
      let(:payload) { "$.master[0].foo" }

      it "sets the value in the array" do
        expect(subject.set(input, "hi")).to eq("master" => [{"foo" => "hi"}, {"bar" => "baz"}])
      end
    end

    context "with a non-empty input" do
      let(:input)   { {"master" => {"detail" => [1, 2, 3]}} }
      let(:payload) { "$.master.result.sum" }

      it "merges the result" do
        expect(subject.set(input, 6)).to eq("master" => {"detail" => [1, 2, 3], "result" => {"sum" => 6}})
      end
    end
  end
end
