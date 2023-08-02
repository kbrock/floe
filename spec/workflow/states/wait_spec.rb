RSpec.describe Floe::Workflow::States::Pass do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["WaitState"] }

  describe "#end?" do
    it "is non-terminal" do
      expect(state.end?).to eq(false)
    end
  end

  describe "#run!" do
    it "sleeps for the requested amount of time" do
      expect(state).to receive(:sleep).with(state.seconds)

      state.run!({})
    end

    it "transitions to the next state" do
      # skip the actual sleep
      expect(state).to receive(:sleep).with(state.seconds)

      next_state, _output = state.run!({})
      expect(next_state).to eq("NextState")
    end
  end

  describe "#status" do
    it "is non-terminal" do
      expect(state.status).to eq("running")
    end
  end
end
