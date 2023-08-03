RSpec.describe Floe::Workflow::States::Succeed do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["SuccessState"] }

  it "#end?" do
    expect(state.end?).to be true
  end

  describe "#run!" do
    it "has no next" do
      next_state, _output = state.run!({})
      expect(next_state).to be_nil
    end
  end

  it "#status" do
    expect(state.status).to eq("success")
  end
end
