RSpec.describe Floe::Workflow::States::Pass do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.current_state }
  let(:workflow) do
    make_workflow(
      ctx, {
        "PassState"    => {
          "Type"       => "Pass",
          "Result"     => {
            "foo" => "bar",
            "bar" => "baz"
          },
          "ResultPath" => "$.result",
          "Next"       => "SuccessState"
        },
        "SuccessState" => {"Type" => "Succeed"}
      }
    )
  end

  describe "#end?" do
    it "is non-terminal" do
      expect(state.end?).to eq(false)
    end
  end

  describe "#run_nonblock!" do
    it "sets the result to the result path" do
      state.run_nonblock!
      expect(ctx.output["result"]).to include({"foo" => "bar", "bar" => "baz"})
      expect(ctx.next_state).to eq("SuccessState")
    end
  end
end
