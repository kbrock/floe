RSpec.describe Floe::Workflow::States::Task do
  let(:input)    { {} }
  let(:ctx)      { Floe::Workflow::Context.new(:input => input) }
  let(:resource) { "docker://hello-world:latest" }
  let(:workflow) { Floe::Workflow.load(GEM_ROOT.join("examples/workflow.asl"), ctx) }

  describe "#run_async!" do
    let(:mock_runner) { double("Floe::Workflow::Runner") }
    let(:input)       { {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}} }
    let(:state)       { described_class.new(workflow, "Task", payload) }
    let(:success)     { true }
    let(:output)      { nil }
    let(:container_ref) { "container-id" }

    before do
      ctx.state["Input"] = input
      allow(Floe::Workflow::Runner).to receive(:for_resource).and_return(mock_runner)
      allow(mock_runner).to receive(:status!).and_return({})
      allow(mock_runner).to receive(:running?).and_return(false)
      allow(mock_runner).to receive(:success?).and_return(success)
      allow(mock_runner).to receive("output").and_return(output)
      allow(mock_runner).to receive(:cleanup)
    end

    describe "Input" do
      context "with no InputPath" do
        let(:payload) { {"Type" => "Task", "Resource" => resource} }

        it "passes the whole context to the resource" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, nil)
            .and_return({"container_ref" => container_ref})

          state.run_nonblock!
        end
      end

      context "with an InputPath" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "InputPath" => "$.foo"} }

        it "filters the context passed to the resource" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, {"bar" => "baz"}, nil)
            .and_return({"container_ref" => container_ref})

          state.run_nonblock!
        end
      end

      context "with Parameters" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "Parameters" => {"var1.$" => "$.foo.bar"}} }

        it "passes the interpolated parameters to the resource" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, {"var1" => "baz"}, nil)
            .and_return({"container_ref" => container_ref})

          state.run_nonblock!
        end
      end
    end

    describe "Output" do
      let(:payload) { {"Type" => "Task", "Resource" => resource} }

      it "uses the last line as output if it is JSON" do
        expect(mock_runner)
          .to receive(:run_async!)
          .with(resource, {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, nil)
        expect(mock_runner).to receive("output").and_return("ABCD\nHELLO\n{\"response\":[\"192.168.1.2\"]}")

        state.run_nonblock!

        expect(ctx.output).to eq("foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}, "response" => ["192.168.1.2"])
      end

      it "returns nil if the output isn't JSON" do
        expect(mock_runner)
          .to receive(:run_async!)
          .with(resource, {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, nil)
        expect(mock_runner).to receive("output").and_return("HELLO")

        state.run_nonblock!

        expect(ctx.output).to eq("foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"})
      end

      context "ResultSelector" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "ResultSelector" => {"ip_addrs.$" => "$.response"}} }

        it "filters the results" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, nil)
          expect(mock_runner).to receive("output").and_return("ABCD\nHELLO\n{\"response\":[\"192.168.1.2\"],\"exit_code\":0}")

          state.run_nonblock!

          expect(ctx.output).to eq("foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}, "ip_addrs" => ["192.168.1.2"])
        end
      end

      context "ResultPath" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "ResultPath" => "$.ip_addrs"} }

        it "inserts the response into the input" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)
          expect(mock_runner).to receive("output").and_return("[\"192.168.1.2\"]")

          state.run_nonblock!

          expect(ctx.output).to eq(
            "foo"      => {"bar" => "baz"},
            "bar"      => {"baz" => "foo"},
            "ip_addrs" => ["192.168.1.2"]
          )
        end
      end

      context "OutputPath" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "ResultPath" => "$.data.ip_addrs", "OutputPath" => output_path} }

        context "with the default '$'" do
          let(:output_path) { "$" }

          it "returns the entire input as the output" do
            expect(mock_runner)
              .to receive(:run_async!)
              .with(resource, input, nil)
            expect(mock_runner).to receive("output").and_return("[\"192.168.1.2\"]")

            state.run_nonblock!

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
            expect(mock_runner)
              .to receive(:run_async!)
              .with(resource, input, nil)
            expect(mock_runner).to receive("output").and_return("[\"192.168.1.2\"]")

            state.run_nonblock!

            expect(ctx.output).to eq("ip_addrs" => ["192.168.1.2"])
          end
        end
      end
    end

    describe "Retry" do
      let(:payload) { {"Type" => "Task", "Resource" => resource, "Retry" => retriers, "TimeoutSeconds" => 2} }
      before { allow(Kernel).to receive(:sleep).and_return(0) }

      context "with specific errors" do
        let(:retriers) { [{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => 1}] }
        let(:success)  { false }
        let(:output)   { {"Error" => "States.Timeout"}.to_json }

        it "retries if that error is raised" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)
            .and_return({"container_ref" => container_ref})

          state.run_nonblock!

          expect(ctx.next_state).to          eq(ctx.state_name)
          expect(ctx.state["Retrier"]).to    eq(["States.Timeout"])
          expect(ctx.state["RetryCount"]).to eq(1)
        end

        context "with multiple retriers" do
          let(:retriers) { [{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => 1}, {"ErrorEquals" => ["Exception"]}] }

          it "resets the retrier if a different exception is raised" do
            expect(mock_runner).to receive(:running?).and_return(false)
            expect(mock_runner).to receive(:success?).and_return(false)
            expect(mock_runner).to receive("output").once.and_return("States.Timeout")
            expect(mock_runner)
              .to receive(:run_async!)
              .with(resource, input, nil)
            expect(state).to receive(:wait).twice.with(:seconds => 2)

            state.run_nonblock!

            expect(ctx.next_state).to          eq(ctx.state_name)
            expect(ctx.state["Retrier"]).to    eq(["States.Timeout"])
            expect(ctx.state["RetryCount"]).to eq(1)

            expect(mock_runner).to receive("output").once.and_return("Exception")

            state.run_nonblock!

            expect(ctx.next_state).to          eq(ctx.state_name)
            expect(ctx.state["Retrier"]).to    eq(["Exception"])
            expect(ctx.state["RetryCount"]).to eq(1)
          end
        end

        it "fails the workflow if the number of retries is greater than MaxAttempts" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)
          expect(state).to receive(:wait).with(:seconds => 2)

          2.times { state.run_nonblock! }

          expect(ctx.next_state).to     be_nil
          expect(ctx.status).to         eq("failure")
          expect(ctx.state["Error"]).to eq("States.Timeout")
        end

        it "fails the workflow if the exception isn't caught" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)
          expect(mock_runner).to receive("output").once.and_return("Exception")

          state.run_nonblock!

          expect(ctx.next_state).to     be_nil
          expect(ctx.status).to         eq("failure")
          expect(ctx.state["Error"]).to eq("Exception")
        end
      end

      context "with a States.ALL retrier" do
        let(:retriers) { [{"ErrorEquals" => ["States.Timeout"]}, {"ErrorEquals" => ["States.ALL"]}] }

        it "retries if any error is raised" do
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)
          expect(mock_runner).to receive("output").once.and_return("ABORT!")
          expect(mock_runner).to receive("output").once.and_return(output)

          state.run_nonblock!
          state.run_nonblock!

          expect(ctx.output).to eq("bar" => {"baz"=>"foo"}, "foo" => {"bar"=>"baz"})
        end
      end

      context "with a Catch" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "Retry" => [{"ErrorEquals" => ["States.Timeout"]}], "Catch" => [{"ErrorEquals" => ["States.ALL"], "Next" => "FailState"}]} }
        let(:success) { false }

        it "retry preceeds catch" do
          expect(mock_runner).to receive("output").once.and_return("States.Timeout")
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)

          state.run_nonblock!

          expect(ctx.next_state).to          eq(ctx.state_name)
          expect(ctx.state["Retrier"]).to    eq(["States.Timeout"])
          expect(ctx.state["RetryCount"]).to eq(1)
        end

        it "invokes the Catch if no retriers match" do
          expect(mock_runner).to receive("output").once.and_return("Exception")
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)

          state.run_nonblock!

          expect(ctx.next_state).to eq("FailState")
        end
      end
    end

    describe "Catch" do
      let(:success) { false }

      context "with specific errors" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "Catch" => [{"ErrorEquals" => ["States.Timeout"], "Next" => "FirstState"}]} }

        it "catches the exception" do
          expect(mock_runner).to receive("output").and_return("States.Timeout")
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)

          state.run_nonblock!

          expect(ctx.next_state).to eq("FirstState")
        end

        it "raises if the exception isn't caught" do
          expect(mock_runner).to receive("output").and_return("Exception")
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)

          state.run_nonblock!

          expect(ctx.next_state).to be_nil
          expect(ctx.status).to     eq("failure")
          expect(ctx.output).to     eq({"Error" => "Exception"})
        end
      end

      context "with a State.ALL catcher" do
        let(:payload) { {"Type" => "Task", "Resource" => resource, "Catch" => [{"ErrorEquals" => ["States.Timeout"], "Next" => "FirstState"}, {"ErrorEquals" => ["States.ALL"], "Next" => "FailState"}]} }

        it "catches a more specific exception" do
          expect(mock_runner).to receive("output").and_return("States.Timeout")
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)

          state.run_nonblock!

          expect(ctx.next_state).to eq("FirstState")
        end

        it "catches the exception and transits to the next state" do
          expect(mock_runner).to receive("output").and_return("Exception")
          expect(mock_runner)
            .to receive(:run_async!)
            .with(resource, input, nil)

          state.run_nonblock!

          expect(ctx.next_state).to eq("FailState")
        end
      end
    end
  end

  describe "#end?" do
    it "with a normal state" do
      state = workflow.states_by_name["FirstState"]
      expect(state.end?).to be false
    end

    it "with an end state" do
      state = workflow.states_by_name["NextState"]
      expect(state.end?).to be true
    end
  end
end
