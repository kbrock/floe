RSpec.describe ManageIQ::Floe::Workflow::States::Choice do
  let(:workflow) { ManageIQ::Floe::Workflow.load(GEM_ROOT.join("examples/workflow.json")) }
  let(:state)    { workflow.states_by_name["ChoiceState"] }

  it "#to_dot" do
    expect(state.to_dot).to eq "  ChoiceState [ shape=diamond ]"
  end

  it "#to_dot_transitions" do
    expect(state.to_dot_transitions).to eq [
      "  ChoiceState -> FirstMatchState [ label=\"$.foo == 1\" ]",
      "  ChoiceState -> SecondMatchState [ label=\"$.foo == 2\" ]",
      "  ChoiceState -> SuccessState [ label=\"$.foo == 3\" ]",
      "  ChoiceState -> FailState [ label=\"Default\" ]"
    ]
  end
end
