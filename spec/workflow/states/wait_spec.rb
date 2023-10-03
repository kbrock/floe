RSpec.describe Floe::Workflow::States::Pass do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.current_state }
  let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "Seconds" => 1, "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }

  describe "#end?" do
    it "is non-terminal" do
      expect(state.end?).to eq(false)
    end
  end

  describe "#start" do
    it "transitions to the next state" do
      state.start(ctx.input)

      expect(ctx.next_state).to eq("SuccessState")
    end
  end

  describe "#running?" do
    context "with seconds" do
      let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "Seconds" => 1, "Next" => "SuccessState"}}) }
      it "is running before finished" do
        state.start(ctx.input)
        expect(state.running?).to be_truthy
      end

      it "is not running after finished" do
        state.start(ctx.input)
        Timecop.travel(Time.now.utc + 10) do
          expect(state.running?).to be_falsey
        end
      end
    end
  end
end
