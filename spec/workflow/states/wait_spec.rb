RSpec.describe Floe::Workflow::States::Pass do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.start_workflow.current_state }
  let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "Seconds" => 1, "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }

  describe "#end?" do
    it "is non-terminal" do
      expect(state.end?).to eq(false)
    end
  end

  describe "#start" do
    it "sets WaitUntil" do
      state.start(ctx.input)

      expect(state.waiting?).to be_truthy
    end
  end

  describe "#finish" do
    it "transitions to the next state" do
      state.start(ctx.input)
      state.finish

      expect(ctx.next_state).to eq("SuccessState")
    end
  end

  describe "#running?" do
    context "with seconds" do
      let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "Seconds" => 1, "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }
      it "is running before finished" do
        state.start(ctx.input)
        expect(state.running?).to be_truthy
      end

      it "is not running after finished" do
        Timecop.travel(Time.now.utc - 10) do
          state.start(ctx.input)
        end
        expect(state.running?).to be_falsey
      end
    end

    context "with secondsPath" do
      let(:input)    { {"expire" => "1"} }
      let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "SecondsPath" => "$.expire", "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }
      it "is running? before finished" do
        state.start(ctx.input)
        expect(state.running?).to be_truthy
      end

      it "is not running after finished" do
        Timecop.travel(Time.now.utc - 10) do
          state.start(ctx.input)
        end
        expect(state.running?).to be_falsey
      end
    end

    context "with timestamp" do
      let(:expiry) { Time.now.utc + 1 }
      let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "Timestamp" => expiry.iso8601, "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }
      it "is running? before finished" do
        state.start(ctx.input)
        expect(state.running?).to be_truthy
      end

      it "is not running after finished" do
        Timecop.travel(Time.now.utc - 10) do
          state.start(ctx.input)
        end
        expect(state.running?).to be_falsey
      end
    end

    context "with timestamp" do
      let(:expiry) { Time.now.utc + 1 }
      let(:input) { {"expire" => expiry.iso8601} }
      let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "TimestampPath" => "$.expire", "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }
      it "is running? before finished" do
        state.start(ctx.input)
        expect(state.running?).to be_truthy
      end

      it "is not running after finished" do
        Timecop.travel(Time.now.utc - 10) do
          state.start(ctx.input)
        end
        expect(state.running?).to be_falsey
      end
    end
  end
end
