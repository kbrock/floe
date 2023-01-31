RSpec.describe ManageIQ::Floe::Workflow::ReferencePath do
  context "with invalid value" do
    it "raises an exception" do
      expect { described_class.new("$.foo@.bar", {}) }.to raise_error(ManageIQ::Floe::InvalidWorkflowError, "Invalid Reference Path")
    end
  end
end
