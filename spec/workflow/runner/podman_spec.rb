RSpec.describe ManageIQ::Floe::Workflow::Runner::Podman do
  let(:subject) { described_class.new }

  describe "#run!" do
    it "raises an exception without a resource" do
      expect { subject.run!(nil) }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "raises an exception for an invalid resource uri" do
      expect { subject.run!("arn:abcd:efgh") }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "calls docker run with the image name" do
      stub_good_run!("podman", :params => ["run", :rm, "hello-world:latest"])

      subject.run!("docker://hello-world:latest")
    end

    it "passes environment variables to podman run" do
      stub_good_run!("podman", :params => ["run", :rm, [:e, "FOO=BAR"], "hello-world:latest"])

      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"})
    end

    it "passes a secrets volume to podman run" do
      stub_good_run!("podman", :params => ["secret", "create", anything, "-"], :in_data => {"luggage_password" => "12345"}.to_json)
      stub_good_run!("podman", :params => ["run", :rm, [:e, "FOO=BAR"], [:secret, anything], "hello-world:latest"])
      stub_good_run("podman", :params => ["secret", "rm", anything])

      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"}, {"luggage_password" => "12345"})
    end
  end
end
