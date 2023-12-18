RSpec.describe Floe::Workflow::States::Fail do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.current_state }
  let(:workflow) do
    make_workflow(
      ctx, {
        "FailState" => {
          "Type"  => "Fail",
          "Error" => "FailStateError",
          "Cause" => "No Matches!"
        }
      }
    )
  end

  it "#end?" do
    expect(state.end?).to be true
  end

  describe "#run_nonblock!" do
    it "populates static values" do
      state.run_nonblock!
      expect(ctx.next_state).to eq(nil)
      expect(ctx.state["Error"]).to eq("FailStateError")
      expect(ctx.state["Cause"]).to eq("No Matches!")
    end

    context "with dynamic error text" do
      let(:input) { {"output" => "xyz", "error_message" => "DynamicError", "cause_message" => "DynamicCause"} }
      let(:workflow) do
        make_workflow(
          ctx, {
            "FailState" => {
              "Type"      => "Fail",
              "ErrorPath" => "$.error_message",
              "CausePath" => "$.cause_message"
            }
          }
        )
      end

      it "populates dynamic values" do
        state.run_nonblock!
        expect(ctx.next_state).to eq(nil)
        expect(ctx.state["Error"]).to eq("DynamicError")
        expect(ctx.state["Cause"]).to eq("DynamicCause")
      end
    end
  end
end
