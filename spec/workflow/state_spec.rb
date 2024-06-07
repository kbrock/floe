RSpec.describe Floe::Workflow::State do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.start_workflow.current_state }
  # picked a state that doesn't instantly finish
  let(:workflow) { make_workflow(ctx, {"WaitState" => {"Type" => "Wait", "Seconds" => 1, "Next" => "SuccessState"}, "SuccessState" => {"Type" => "Succeed"}}) }

  describe "#started?" do
    it "is not started yet" do
      expect(state.started?).to eq(false)
    end

    it "is started" do
      state.start(ctx.input)
      expect(state.started?).to eq(true)
    end

    it "is finished" do
      state.start(ctx.input)
      state.finish

      state.start(ctx.input)
      expect(state.started?).to eq(true)
    end
  end

  describe "#finished?" do
    it "is not started yet" do
      expect(state.finished?).to eq(false)
    end

    it "is started" do
      state.start(ctx.input)
      expect(state.finished?).to eq(false)
    end

    it "is finished" do
      state.start(ctx.input)
      state.finish

      state.start(ctx.input)
      expect(state.finished?).to eq(true)
    end
  end
end
