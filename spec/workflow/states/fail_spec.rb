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

  it "#run!" do
    state.run!(input)
    expect(ctx.next_state).to eq(nil)
    expect(ctx.state["Error"]).to eq("FailStateError")
    expect(ctx.state["Cause"]).to eq("No Matches!")
  end
end
