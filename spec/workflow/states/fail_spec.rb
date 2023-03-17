RSpec.describe Floe::Workflow::States::Fail do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["FailState"] }

  it "#end?" do
    expect(state.end?).to be true
  end

  it "#to_dot" do
    expect(state.to_dot).to eq "  FailState [ style=bold color=red ]"
  end

  it "#to_dot_transitions" do
    expect(state.to_dot_transitions).to be_empty
  end
end
