require 'active_support/time'

RSpec.describe Floe::Workflow do
  let(:now) { Time.now.utc }

  describe "#new" do
    it "sets initial state" do
      input = {"input" => "value"}.freeze

      workflow, _ctx = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)
    end
  end

  describe "#run!" do
    let(:input) { {"input" => "value"}.freeze }

    it "sets execution variables for success" do
      workflow, ctx = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})
      workflow.run!

      # state
      expect(ctx.state["EnteredTime"]).to be_within(1.second).of(now)
      expect(ctx.state["Guid"]).to be
      expect(ctx.state["Name"]).to eq("FirstState")
      expect(ctx.state["Input"]).to eq(input)
      expect(ctx.state["Output"]).to eq(input)
      expect(ctx.state["FinishedTime"]).to be_within(1.second).of(now)
      expect(ctx.state["Duration"]).to be <= 1

      # execution
      expect(ctx.execution["StartTime"]).to be_within(1.second).of(now)
      # expect(ctx.execution["EndTime"]).to be_within(1.second).of(now)

      # final results
      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
    end
  end

  describe "#step" do
    it "runs a step" do
      input = {"input" => "value"}.freeze

      workflow, _ctx = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)

      workflow.step

      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
    end
  end

  private

  def make_workflow(input, payload, creds: {})
    context = Floe::Workflow::Context.new(:input => input)
    workflow = Floe::Workflow.new(make_payload(payload), context, creds)
    [workflow, context]
  end

  def make_payload(states)
    start_at ||= states.keys.first

    {
      "Comment" => "Sample",
      "StartAt" => start_at,
      "States"  => states
    }
  end
end
