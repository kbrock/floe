RSpec.describe Floe::Workflow::States::Succeed do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["SuccessState"] }

  it "#end?" do
    expect(state.end?).to be true
  end
end
