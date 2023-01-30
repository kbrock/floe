RSpec.describe ManageIQ::Floe::Workflow::States::Pass do
  let(:workflow) { ManageIQ::Floe::Workflow.load(GEM_ROOT.join("examples/workflow.json")) }
  let(:state)    { workflow.states_by_name["PassState"] }

  describe "#run!" do
    it "sets the result to the result path" do
      state.run!
      expect(workflow.context["result"]).to include(state.result)
    end
  end

  it "#to_dot" do
    expect(state.to_dot).to eq "  PassState"
  end

  it "#to_dot_transitions" do
    expect(state.to_dot_transitions).to eq [
      "  PassState -> NextState"
    ]
  end
end
