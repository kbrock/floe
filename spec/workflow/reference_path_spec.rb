RSpec.describe Floe::Workflow::ReferencePath do
  let(:subject) { described_class.new(payload) }

  describe "#initialize" do
    context "with invalid value" do
      let(:payload) { "$.foo@.bar" }

      it "raises an exception" do
        expect { subject }.to raise_error(Floe::InvalidWorkflowError, "Invalid Reference Path")
      end
    end
  end

  describe "#get" do
    context "with a simple path" do
      let(:payload) { "$" }
      let(:input)   { {"hello" => "world"} }

      it "returns the input" do
        expect(subject.get(input)).to eq(input)
      end
    end

    context "with an array dereference" do
      let(:payload) { "$['store'][1]['book']" }
      let(:input)   { {"store" => [{"book" => "Advanced ASL"}, {"book" => "ASL For Dummies"}]} }

      it "returns the value from the array" do
        expect(subject.get(input)).to eq("ASL For Dummies")
      end

      context "with a missing value" do
        let(:input)   { {"store" => []} }

        it "returns nil" do
          expect(subject.get(input)).to be_nil
        end
      end
    end
  end

  describe "#set" do
    let(:payload) { "$" }
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
      let(:payload) { "$.master[1].bar" }

      it "sets the value in the array" do
        expect(subject.set(input, "hi")).to eq("master" => [{"foo" => "bar"}, {"bar" => "hi"}])
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
