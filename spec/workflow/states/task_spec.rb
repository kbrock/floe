RSpec.describe ManageIQ::Floe::Workflow::States::Task do
  let(:workflow) { ManageIQ::Floe::Workflow.load(GEM_ROOT.join("examples/workflow.json")) }

  describe "#run" do
    let(:mock_runner) { double("ManageIQ::Floe::Workflow::Runner") }
    before { allow(ManageIQ::Floe::Workflow::Runner).to receive(:for_resource).and_return(mock_runner) }

    describe "Input" do
      let(:state) { described_class.new(workflow, "Task", payload) }

      before do
        workflow.context["foo"] = {"bar" => "baz"}
        workflow.context["bar"] = {"baz" => "foo"}
      end

      context "with no InputPath" do
        let(:payload) { {"Type" => "Task", "Resource" => "docker://hello-world:latest"} }

        it "passes the whole context to the resource" do
          expect(mock_runner)
            .to receive(:run!)
            .with(payload["Resource"], {"foo" => {"bar" => "baz"}, "bar" => {"baz" => "foo"}}, nil)

          state.run!
        end
      end

      context "with an InputPath" do
        let(:payload) { {"Type" => "Task", "Resource" => "docker://hello-world:latest", "InputPath" => "$.foo"} }

        it "filters the context passed to the resource" do
          expect(mock_runner)
            .to receive(:run!)
            .with(payload["Resource"], {"bar" => "baz"}, nil)

          state.run!
        end
      end

      context "with Parameters" do
        let(:payload) { {"Type" => "Task", "Resource" => "docker://hello-world:latest", "Parameters" => {"var1.$" => "$$.foo.bar"}} }

        it "passes the interpolated parameters to the resource" do
          expect(mock_runner)
            .to receive(:run!)
            .with(payload["Resource"], {"var1" => "baz"}, nil)

          state.run!
        end
      end
    end

    describe "Output" do
      let(:state) { described_class.new(workflow, "Task", payload) }

      context "ResultSelector" do
        let(:payload) { {"Type" => "Task", "Resource" => "docker://hello-world:latest", "ResultSelector" => {"ip_addrs.$" => "$.response"}} }

        it "filters the results" do
          expect(mock_runner)
            .to receive(:run!)
            .with(payload["Resource"], {}, nil)
            .and_return([0, {"response" => ["192.168.1.2"], "exit_code" => 0}])

          _, results = state.run!

          expect(results).to eq("ip_addrs" => ["192.168.1.2"])
        end
      end
    end
  end

  context "with a normal state" do
    let(:state) { workflow.states_by_name["FirstState"] }

    it "#end?" do
      expect(state.end?).to be false
    end

    it "#to_dot" do
      expect(state.to_dot).to eq "  FirstState"
    end

    it "#to_dot_transitions" do
      expect(state.to_dot_transitions).to eq ["  FirstState -> ChoiceState"]
    end
  end

  context "with an end state" do
    let(:state) { workflow.states_by_name["NextState"] }

    it "#end?" do
      expect(state.end?).to be true
    end

    it "#to_dot" do
      expect(state.to_dot).to eq "  NextState [ style=bold ]"
    end

    it "#to_dot_transitions" do
      expect(state.to_dot_transitions).to be_empty
    end
  end
end
