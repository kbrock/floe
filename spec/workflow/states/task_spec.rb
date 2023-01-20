RSpec.describe ManageIQ::Floe::Workflow::States::Succeed do
  let(:workflow) { ManageIQ::Floe::Workflow.load(GEM_ROOT.join("examples/workflow.json")) }

  context "with a normal state" do
    let(:state) { workflow.states_by_name["FirstState"] }

    it "#end?" do
      expect(state.end?).to be false
    end

    it "#to_dot" do
      expect(state.to_dot).to eq "  FirstState"
    end

    it "#to_dot_transitions" do
      expect(state.to_dot_transitions).to eq ["  FirstState -> ChoiceState"]
    end
  end

  context "with an end state" do
    let(:state) { workflow.states_by_name["NextState"] }

    it "#end?" do
      expect(state.end?).to be true
    end

    it "#to_dot" do
      expect(state.to_dot).to eq "  NextState [ style=bold ]"
    end

    it "#to_dot_transitions" do
      expect(state.to_dot_transitions).to be_empty
    end
  end
end
