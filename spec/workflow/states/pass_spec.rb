RSpec.describe Floe::Workflow::States::Pass do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["PassState"] }

  describe "#run!" do
    it "sets the result to the result path" do
      _, output = state.run!({})
      expect(output["result"]).to include(state.result)
    end
  end
end
