require 'active_support/time'

RSpec.describe Floe::Workflow do
  let(:now)     { Time.now.utc }
  let(:input)   { {"input" => "value"}.freeze }
  let(:context) { Floe::Workflow::Context.new(:input => input) }

  describe "#new" do
    it "sets initial state" do
      workflow = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)

      expect(context.status).to eq("pending")
      expect(context.started?).to eq(false)
      expect(context.running?).to eq(false)
      expect(context.ended?).to eq(false)
    end
  end

  describe "#run!" do
    it "sets execution variables for success" do
      workflow = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})
      workflow.run!

      # state
      expect(context.state["EnteredTime"]).to be_within(1.second).of(now)
      expect(context.state["Guid"]).to be
      expect(context.state_name).to eq("FirstState")
      expect(context.input).to eq(input)
      expect(context.output).to eq(input)
      expect(context.state["FinishedTime"]).to be_within(1.second).of(now)
      expect(context.state["Duration"]).to be <= 1
      expect(context.status).to eq("success")

      # execution
      expect(context.started?).to eq(true)
      expect(context.running?).to eq(false)
      expect(context.ended?).to eq(true)

      # final results
      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
    end

    it "sets execution variables for failure" do
      workflow = make_workflow(input, {"FirstState" => {"Type" => "Fail", "Cause" => "Bad Stuff", "Error" => "Issue"}})
      workflow.run!

      # state
      expect(context.state["EnteredTime"]).to be_within(1.second).of(now)
      expect(context.state["Guid"]).to be
      expect(context.state_name).to eq("FirstState")
      expect(context.input).to eq(input)
      expect(context.output).to eq(input)
      expect(context.state["FinishedTime"]).to be_within(1.second).of(now)
      expect(context.state["Duration"]).to be <= 1
      expect(context.state["Cause"]).to eq("Bad Stuff")
      expect(context.state["Error"]).to eq("Issue")
      expect(context.status).to eq("failure")

      # execution
      expect(context.started?).to eq(true)
      expect(context.running?).to eq(false)
      expect(context.ended?).to eq(true)

      # final results
      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("failure")
      expect(workflow.end?).to eq(true)
    end
  end

  describe "#step" do
    it "runs a success step" do

      workflow = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)
      expect(context.status).to eq("pending")
      expect(context.started?).to eq(false)
      expect(context.running?).to eq(false)
      expect(context.ended?).to eq(false)

      workflow.step

      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
      expect(context.output).to eq(input)
      expect(context.status).to eq("success")
      expect(context.started?).to eq(true)
      expect(context.running?).to eq(false)
      expect(context.ended?).to eq(true)
    end
  end

  private

  def make_workflow(input, payload, creds: {})
    Floe::Workflow.new(make_payload(payload), context, creds)
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
