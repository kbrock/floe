RSpec.describe Floe::Workflow::States::Choice do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.current_state }
  let(:workflow) do
    make_workflow(
      ctx, {
        "ChoiceState"      => {
          "Type"    => "Choice",
          "Choices" => [
            {
              "Variable"      => "$.foo",
              "NumericEquals" => 1,
              "Next"          => "FirstMatchState"
            },
            {
              "Variable"      => "$.foo",
              "NumericEquals" => 2,
              "Next"          => "SecondMatchState"
            },
          ],
          "Default" => "DefaultState"
        },
        "FirstMatchState"  => {"Type" => "Succeed"},
        "SecondMatchState" => {"Type" => "Succeed"},
        "DefaultState"     => {"Type" => "Succeed"}
      }
    )
  end

  it "#end?" do
    expect(state.end?).to eq(false)
  end

  describe "#run_nonblock!" do
    context "with a missing variable" do
      it "raises an exception" do
        expect { state.run_nonblock! }.to raise_error(RuntimeError, "No such variable [$.foo]")
      end
    end

    context "with an input value matching a condition" do
      let(:input) { {"foo" => 1} }

      it "returns the next state" do
        state.run_nonblock!
        expect(ctx.next_state).to eq("FirstMatchState")
      end
    end

    context "with an input value not matching any condition" do
      let(:input) { {"foo" => 4} }

      it "returns the default state" do
        state.run_nonblock!
        expect(ctx.next_state).to eq("DefaultState")
      end
    end
  end
end
