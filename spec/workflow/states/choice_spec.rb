RSpec.describe ManageIQ::Floe::Workflow::States::Choice do
  let(:workflow) { ManageIQ::Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["ChoiceState"] }
  let(:inputs)   { {} }

  describe "#run!" do
    let(:subject) { state.run!(inputs) }

    context "with a missing variable" do
      it "raises an exception" do
        expect { subject }.to raise_error(RuntimeError, "No such variable [$.foo]")
      end
    end

    context "with an input value matching a condition" do
      let(:inputs) { {"foo" => 1} }

      it "returns the next state" do
        next_state, = subject
        expect(next_state).to eq(workflow.states_by_name["FirstMatchState"])
      end
    end

    context "with an input value not matching any condition" do
      let(:inputs) { {"foo" => 4} }

      it "returns the default state" do
        next_state, = subject
        expect(next_state).to eq(workflow.states_by_name["FailState"])
      end
    end
  end

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
