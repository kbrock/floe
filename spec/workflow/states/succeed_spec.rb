RSpec.describe ManageIQ::Floe::Workflow::States::Succeed do
  let(:workflow) { ManageIQ::Floe::Workflow.load(GEM_ROOT.join("examples/workflow.json")) }
  let(:state)    { workflow.states_by_name["SuccessState"] }

  it "#end?" do
    expect(state.end?).to be true
  end

  it "#to_dot" do
    expect(state.to_dot).to eq "  SuccessState [ style=bold color=green ]"
  end

  it "#to_dot_transitions" do
    expect(state.to_dot_transitions).to be_empty
  end
end
