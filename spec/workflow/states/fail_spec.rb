RSpec.describe Floe::Workflow::States::Fail do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["FailState"] }

  it "#end?" do
    expect(state.end?).to be true
  end

  it "#run!" do
    next_state, _output = state.run!({})
    expect(next_state).to eq(nil)
  end

  it "#status" do
    expect(state.status).to eq("errored")
  end
end
