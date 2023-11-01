RSpec.describe Floe::Workflow::States::Task do
  let(:input)    { {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:resource) { "docker://hello-world:latest" }

  describe "#run_async!" do
    let(:mock_runner) { double("Floe::Workflow::Runner") }
    let(:container_ref) { "container-d" }

    before do
      allow(Floe::Workflow::Runner).to receive(:for_resource).and_return(mock_runner)
    end

    describe "Input" do
      context "with no InputPath" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource}}) }

        it "passes the whole context to the resource" do
          expect_run_async({"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, :output => "hello, world!")

          workflow.current_state.run_nonblock!
        end
      end

      context "with an InputPath" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "InputPath" => "$.foo"}}) }

        it "filters the context passed to the resource" do
          expect_run_async({"bar" => "baz"}, :output => nil)

          workflow.current_state.run_nonblock!
        end
      end

      context "with Parameters" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "Parameters" => {"var1.$" => "$.foo.bar"}}}) }

        it "passes the interpolated parameters to the resource" do
          expect_run_async({"var1" => "baz"}, :output => nil)

          workflow.current_state.run_nonblock!
        end
      end
    end

    describe "Output" do
      let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource}}) }

      it "uses the last line as output if it is JSON" do
        expect_run_async({"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, :output => "ABCD\nHELLO\n{\"response\":[\"192.168.1.2\"]}")

        workflow.current_state.run_nonblock!

        expect(ctx.output).to eq("foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}, "response" => ["192.168.1.2"])
      end

      context "with an error" do
        it "uses the last error line as output if it is JSON" do
          expect_run_async({"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, :output => "ABCD\nHELLO\n{\"Error\":\"Custom Error\"}", :success => false)

          workflow.current_state.run_nonblock!

          expect(ctx.output).to eq({"Error" => "Custom Error"})
        end
      end

      it "returns nil if the output isn't JSON" do
        expect_run_async({"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, :output => "HELLO")

        workflow.current_state.run_nonblock!

        expect(ctx.output).to eq("foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"})
      end

      context "ResultSelector" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "ResultSelector" => {"ip_addrs.$" => "$.response"}}}) }

        it "filters the results" do
          expect_run_async({"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, :output => "ABCD\nHELLO\n{\"response\":[\"192.168.1.2\"],\"exit_code\":0}")

          workflow.current_state.run_nonblock!

          expect(ctx.output).to eq("foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}, "ip_addrs" => ["192.168.1.2"])
        end
      end

      context "ResultPath" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "ResultPath" => "$.ip_addrs"}}) }

        it "inserts the response into the input" do
          expect_run_async(input, :output => "[\"192.168.1.2\"]")

          workflow.current_state.run_nonblock!

          expect(ctx.output).to eq(
            "foo"      => {"bar" => "baz"},
            "bar"      => {"baz" => "foo"},
            "ip_addrs" => ["192.168.1.2"]
          )
        end
      end

      context "OutputPath" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "ResultPath" => "$.data.ip_addrs", "OutputPath" => output_path}}) }

        context "with the default '$'" do
          let(:output_path) { "$" }

          it "returns the entire input as the output" do
            expect_run_async(input, :output => "[\"192.168.1.2\"]")

            workflow.current_state.run_nonblock!

            expect(ctx.output).to eq(
              "foo"  => {"bar" => "baz"},
              "bar"  => {"baz" => "foo"},
              "data" => {"ip_addrs" => ["192.168.1.2"]}
            )
          end
        end

        context "with a path" do
          let(:output_path) { "$.data" }

          it "filters the output" do
            expect_run_async(input, :output => "[\"192.168.1.2\"]")

            workflow.current_state.run_nonblock!

            expect(ctx.output).to eq("ip_addrs" => ["192.168.1.2"])
          end
        end
      end
    end

    describe "Retry" do
      let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "Retry" => retriers, "TimeoutSeconds" => 2}}) }

      context "with specific errors" do
        let(:retriers) { [{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => 1}] }

        it "retries if that error is raised" do
          expect_run_async(input, :error => "States.Timeout")

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to          eq(ctx.state_name)
          expect(ctx.state["Retrier"]).to    eq(["States.Timeout"])
          expect(ctx.state["RetryCount"]).to eq(1)
        end

        context "with multiple retriers" do
          let(:retriers) { [{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => 1}, {"ErrorEquals" => ["Exception"]}] }

          it "resets the retrier if a different exception is raised" do
            expect_run_async(input, :error => "States.Timeout")
            expect(workflow.current_state).to receive(:wait).twice.with(:seconds => 2)

            workflow.current_state.run_nonblock!

            expect(ctx.next_state).to          eq(ctx.state_name)
            expect(ctx.state["Retrier"]).to    eq(["States.Timeout"])
            expect(ctx.state["RetryCount"]).to eq(1)

            expect(mock_runner).to receive("output").once.and_return("Exception")

            workflow.current_state.run_nonblock!

            expect(ctx.next_state).to          eq(ctx.state_name)
            expect(ctx.state["Retrier"]).to    eq(["Exception"])
            expect(ctx.state["RetryCount"]).to eq(1)
          end
        end

        it "fails the workflow if the number of retries is greater than MaxAttempts" do
          expect_run_async(input, :error => "States.Timeout")
          expect(workflow.current_state).to receive(:wait).with(:seconds => 2)

          2.times { workflow.current_state.run_nonblock! }

          expect(ctx.next_state).to     be_nil
          expect(ctx.status).to         eq("failure")
          expect(ctx.state["Error"]).to eq("States.Timeout")
        end

        it "fails the workflow if the exception isn't caught" do
          expect_run_async(input, :output => "Exception", :success => false)

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to     be_nil
          expect(ctx.status).to         eq("failure")
          expect(ctx.state["Error"]).to eq("Exception")
        end
      end

      context "with a States.ALL retrier" do
        let(:retriers) { [{"ErrorEquals" => ["States.Timeout"]}, {"ErrorEquals" => ["States.ALL"]}] }

        it "retries if any error is raised" do
          expect_run_async(input, :success => true)
          expect(mock_runner).to receive("output").once.and_return("ABORT!")
          expect(mock_runner).to receive("output").once.and_return(nil)

          2.times { workflow.current_state.run_nonblock! }

          expect(ctx.output).to eq("bar" => {"baz"=>"foo"}, "foo" => {"bar"=>"baz"})
        end
      end

      context "with a Catch" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "Retry" => [{"ErrorEquals" => ["States.Timeout"]}], "Catch" => [{"ErrorEquals" => ["States.ALL"], "Next" => "FailState"}]}}) }

        it "retry preceeds catch" do
          expect_run_async(input, :error => "States.Timeout")

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to          eq(ctx.state_name)
          expect(ctx.state["Retrier"]).to    eq(["States.Timeout"])
          expect(ctx.state["RetryCount"]).to eq(1)
        end

        it "invokes the Catch if no retriers match" do
          expect_run_async(input, :error => "Exception")

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to eq("FailState")
        end
      end
    end

    describe "Catch" do
      context "with specific errors" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "Catch" => [{"ErrorEquals" => ["States.Timeout"], "Next" => "FirstState"}]}}) }

        it "catches the exception" do
          expect_run_async(input, :output => "States.Timeout", :success => false)

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to eq("FirstState")
        end

        it "raises if the exception isn't caught" do
          expect_run_async(input, :output => "Exception", :success => false)

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to be_nil
          expect(ctx.status).to     eq("failure")
          expect(ctx.output).to     eq({"Error" => "Exception"})
        end
      end

      context "with a State.ALL catcher" do
        let(:workflow) { make_workflow(ctx, {"State" => {"Type" => "Task", "Resource" => resource, "Catch" => [{"ErrorEquals" => ["States.Timeout"], "Next" => "FirstState"}, {"ErrorEquals" => ["States.ALL"], "Next" => "FailState"}]}}) }

        it "catches a more specific exception" do
          expect_run_async(input, :output => "States.Timeout", :success => false)

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to eq("FirstState")
        end

        it "catches the exception and transits to the next state" do
          expect_run_async(input, :output => "Exception", :success => false)

          workflow.current_state.run_nonblock!

          expect(ctx.next_state).to eq("FailState")
        end
      end
    end
  end

  describe "#end?" do
    it "with a normal state" do
      workflow = make_workflow(ctx, {"FirstState" => {"Type" => "Task", "Resource" => resource, "Next" => "ChoiceState"}})
      state = workflow.current_state
      expect(state.end?).to be false
    end

    it "with an end state" do
      workflow = make_workflow(ctx, {"NextState" => {"Type" => "Task", "Resource" => "docker://agrare/hello-world:latest", "End" => true}})
      state = workflow.current_state
      expect(state.end?).to be true
    end
  end

  def expect_run_async(parameters, output: :none, error: nil, cause: nil, success: nil)
    success = error.nil? if success.nil?
    output = {"Error" => error, "Cause" => cause}.compact.to_json if error
    allow(mock_runner).to receive(:status!).and_return({})
    allow(mock_runner).to receive(:running?).and_return(false)
    allow(mock_runner).to receive(:success?).and_return(success) unless success.nil?
    allow(mock_runner).to receive(:output).and_return(output) if output != :none
    allow(mock_runner).to receive(:cleanup)

    expect(mock_runner)
      .to receive(:run_async!)
      .with(resource, parameters, nil)
      .and_return({"container_ref" => container_ref})
  end
end
