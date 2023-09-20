RSpec.describe Floe::Workflow::States::Succeed do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:state)    { workflow.current_state }
  let(:workflow) { make_workflow(ctx, {"SuccessState" => {"Type" => "Succeed"}}) }

  it "#end?" do
    expect(state.end?).to be true
  end

  describe "#run!" do
    it "has no next" do
      state.run!(input)
      expect(ctx.next_state).to eq(nil)
    end
  end
end
