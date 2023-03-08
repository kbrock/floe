RSpec.describe ManageIQ::Floe::Workflow::Runner::Kubernetes do
  let(:subject) { described_class.new }

  describe "#run!" do
    it "raises an exception without a resource" do
      expect { subject.run!(nil) }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "raises an exception for an invalid resource uri" do
      expect { subject.run!("arn:abcd:efgh") }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "calls kubectl run with the image name" do
      stub_good_run!(
        "kubectl",
        :params => [
          "run",
          :rm,
          :attach,
          [:image, "hello-world:latest"],
          [:restart, "Never"],
          [:namespace, "default"],
          a_string_including("hello-world-"),
          a_string_including("--overrides")
        ]
      )

      subject.run!("docker://hello-world:latest")
    end

    it "passes environment variables to kubectl run" do
      stub_good_run!(
        "kubectl",
        :params => [
          "run",
          :rm,
          :attach,
          [:image, "hello-world:latest"],
          [:restart, "Never"],
          [:namespace, "default"],
          a_string_including("hello-world-"),
          a_string_including("\"env\":[{\"name\":\"FOO\",\"value\":\"BAR\"}]")
        ]
      )

      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"})
    end

    it "passes a secrets volume to kubectl run" do
      stub_good_run!("kubectl", :params => ["create", "-f", "-"], :in_data => a_string_including("kind: Secret"))
      stub_good_run!(
        "kubectl",
        :params => [
          "run",
          :rm,
          :attach,
          [:image, "hello-world:latest"],
          [:restart, "Never"],
          [:namespace, "default"],
          a_string_including("hello-world-"),
          a_string_including("\"env\":[{\"name\":\"FOO\",\"value\":\"BAR\"},{\"name\":\"SECRETS\",\"value\":\"/run/secrets")
        ]
      )
      stub_good_run!("kubectl", :params => ["delete", "secret", anything, [:namespace, "default"]])

      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"}, {"luggage_password" => "12345"})
    end
  end
end
