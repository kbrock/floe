RSpec.describe Floe::Workflow::Context do
  describe "#new" do
    let(:input) { {"x" => "y"}.freeze }

    it "sets input" do
      ctx = described_class.new(:input => input)
      expect(ctx.execution["Input"]).to eq(input)
    end
  end
end
