RSpec.describe Floe::Workflow::States::Pass do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["PassState"] }

  describe "#end?" do
    it "is non-terminal" do
      expect(state.end?).to eq(false)
    end
    # TODO: test @end
  end

  describe "#run!" do
    it "sets the result to the result path" do
      next_state, output = state.run!({})
      expect(output["result"]).to include(state.result)
      expect(next_state).to eq("WaitState")
    end
  end

  describe "#status" do
    it "is non-terminal" do
      expect(state.status).to eq("running")
    end
    # TODO: test @end
  end
end
