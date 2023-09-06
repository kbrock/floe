RSpec.describe Floe::Workflow::States::Pass do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["WaitState"] }

  describe "#end?" do
    it "is non-terminal" do
      expect(state.end?).to eq(false)
    end
  end

  describe "#run_async!" do
    it "transitions to the next state" do
      state.run_async!({})

      expect(workflow.context.next_state).to eq("NextState")
    end
  end

  describe "#running?" do
    before { workflow.context.state["EnteredTime"] = entered_time }

    context "before the sleep has finished" do
      let(:entered_time) { Time.now.utc }

      it "returns true" do
        expect(state.running?).to be_truthy
      end
    end

    context "after the sleep has finished" do
      let(:entered_time) { Time.now.utc - 10 }

      it "returns false" do
        expect(state.running?).to be_falsey
      end
    end
  end
end
