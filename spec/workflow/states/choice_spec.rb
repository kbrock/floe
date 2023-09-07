RSpec.describe Floe::Workflow::States::Choice do
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl")) }
  let(:state)    { workflow.states_by_name["ChoiceState"] }
  let(:inputs)   { {} }

  it "#end?" do
    expect(state.end?).to eq(false)
  end

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
        expect(next_state).to eq("FirstMatchState")
      end
    end

    context "with an input value not matching any condition" do
      let(:inputs) { {"foo" => 4} }

      it "returns the default state" do
        next_state, = subject
        expect(next_state).to eq("FailState")
      end
    end
  end
end
