require 'active_support/time'

RSpec.describe Floe::Workflow do
  let(:now)   { Time.now.utc }
  let(:input) { {"input" => "value"}.freeze }
  let(:ctx)   { Floe::Workflow::Context.new(:input => input) }

  describe "#new" do
    it "sets initial state" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)

      expect(ctx.status).to eq("pending")
      expect(ctx.started?).to eq(false)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(false)
    end

    # I would prefer this not be here, but it is, so lets test it
    it "sets context to proper start_at" do
      make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})
      expect(ctx.state_name).to eq("FirstState")
      expect(ctx.input).to eq(input)
    end
  end

  describe "#run!" do
    it "sets execution variables for success" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})
      workflow.run!

      # state
      expect(Time.parse(ctx.state["EnteredTime"])).to be_within(1.second).of(now)
      expect(Time.parse(ctx.state["FinishedTime"])).to be_within(1.second).of(now)
      expect(ctx.state["Guid"]).to be
      expect(ctx.state_name).to eq("FirstState")
      expect(ctx.input).to eq(input)
      expect(ctx.output).to eq(input)
      expect(ctx.state["Duration"].to_f).to be <= 1
      expect(ctx.status).to eq("success")

      # execution
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)

      # final results
      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
    end

    it "sets execution variables for failure" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Fail", "Cause" => "Bad Stuff", "Error" => "Issue"}})
      workflow.run!

      # state
      expect(Time.parse(ctx.state["EnteredTime"])).to be_within(1.second).of(now)
      expect(Time.parse(ctx.state["FinishedTime"])).to be_within(1.second).of(now)
      expect(ctx.state["Guid"]).to be
      expect(ctx.state_name).to eq("FirstState")
      expect(ctx.input).to eq(input)
      expect(ctx.output).to eq(input)
      expect(ctx.state["Duration"].to_f).to be <= 1
      expect(ctx.state["Cause"]).to eq("Bad Stuff")
      expect(ctx.state["Error"]).to eq("Issue")
      expect(ctx.status).to eq("failure")

      # execution
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)

      # final results
      expect(workflow.output).to eq(input) # TODO: think Cause and Error should be here
      expect(workflow.status).to eq("failure")
      expect(workflow.end?).to eq(true)
    end
  end

  describe "#run_nonblock" do
    it "starts the first state" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Wait", "Seconds" => 10, "End" => true}})
      workflow.run_nonblock

      expect(ctx.started?).to eq(true)
    end

    it "doesn't wait for the state to finish" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Wait", "Seconds" => 10, "End" => true}})
      workflow.run_nonblock

      expect(ctx.running?).to eq(true)
      expect(ctx.ended?).to   eq(false)
    end
  end

  describe "#step" do
    it "runs a success step" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)
      expect(ctx.status).to eq("pending")
      expect(ctx.started?).to eq(false)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(false)

      workflow.step

      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
      expect(ctx.output).to eq(input)
      expect(ctx.status).to eq("success")
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)
    end
  end

  describe "#step_nonblock" do
    context "with a workflow that hasn't started yet" do
      it "starts the first step" do
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Wait", "Seconds" => 10, "End" => true}})
        workflow.step_nonblock

        expect(workflow.status).to eq("running")
        expect(workflow.end?).to   eq(false)
      end
    end

    context "with a running state" do
      it "returns Try again" do
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Wait", "Seconds" => 10, "End" => true}})
        expect(workflow.step_nonblock).to eq(Errno::EAGAIN)
      end
    end

    context "with a state that has finished" do
      it "completes the final tasks for a state" do
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Wait", "Seconds" => 10, "End" => true}})

        # Start the workflow
        workflow.run_nonblock

        # Mark the Wait state as having started 1 minute ago
        ctx.state["EnteredTime"] = (Time.now.utc - 60).iso8601

        # step_nonblock should return 0 and mark the workflow as completed
        expect(workflow.step_nonblock).to eq(0)

        expect(workflow.output).to eq(input)
        expect(workflow.status).to eq("success")
        expect(workflow.end?).to eq(true)
        expect(ctx.output).to eq(input)
        expect(ctx.status).to eq("success")
        expect(ctx.started?).to eq(true)
        expect(ctx.running?).to eq(false)
        expect(ctx.ended?).to eq(true)
      end
    end

    it "return Operation not permitted if workflow has ended" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})

      ctx.execution["EndTime"] = Time.now.utc

      expect(workflow.step_nonblock).to eq(Errno::EPERM)
    end

    it "takes 2 steps" do
      workflow = make_workflow(
        ctx, {
          "FirstState"  => {"Type" => "Pass", "Next" => "SecondState"},
          "SecondState" => {"Type" => "Succeed"}
        }
      )

      expect(ctx.status).to eq("pending")
      expect(ctx.started?).to eq(false)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(false)

      workflow.step_nonblock

      expect(ctx.status).to eq("running")

      # execution
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(true)
      expect(ctx.ended?).to eq(false)

      expect(workflow.output).to be_nil

      # second step

      workflow.step_nonblock

      expect(ctx.state_name).to eq("SecondState")
      expect(ctx.status).to eq("success")

      # execution
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)

      expect(workflow.output).to eq(input)
    end
  end

  describe "#step_nonblock_wait" do
    context "with a state that hasn't started yet" do
      it "returns 0" do
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})
        expect(workflow.step_nonblock_wait).to eq(0)
      end
    end

    context "with a state that has finished" do
      it "return 0" do
        ctx.state["EnteredTime"] = Time.now.utc.iso8601
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})
        expect(workflow.current_state).to receive(:running?).and_return(false)
        expect(workflow.step_nonblock_wait).to eq(0)
      end
    end

    context "with a state that is running" do
      it "returns Try again" do
        ctx.state["EnteredTime"] = Time.now.utc.iso8601
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Task", "Resource" => "docker://agrare/hello-world:latest"}})
        expect(workflow.current_state).to receive(:running?).and_return(true)
        expect(workflow.step_nonblock_wait(:timeout => 0)).to eq(Errno::EAGAIN)
      end
    end
  end

  describe "#step_nonblock_ready?" do
    context "with a state that hasn't started yet" do
      it "returns true" do
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})
        expect(workflow.step_nonblock_ready?).to be_truthy
      end
    end

    context "with a state that has finished" do
      it "return true" do
        ctx.state["EnteredTime"] = Time.now.utc.iso8601
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Succeed"}})
        expect(workflow.current_state).to receive(:running?).and_return(false)
        expect(workflow.step_nonblock_ready?).to be_truthy
      end
    end

    context "with a state that is running" do
      it "returns false" do
        ctx.state["EnteredTime"] = Time.now.utc.iso8601
        workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Task", "Resource" => "docker://agrare/hello-world:latest"}})
        expect(workflow.current_state).to receive(:running?).and_return(true)
        expect(workflow.step_nonblock_ready?).to be_falsey
      end
    end
  end
end