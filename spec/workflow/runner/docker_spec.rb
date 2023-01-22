RSpec.describe ManageIQ::Floe::Workflow::Runner::Docker do
  require "awesome_spawn"

  let(:subject) { described_class.new }
  let(:result)  { AwesomeSpawn::CommandResult.new(nil, nil, nil, 0) }

  describe "#run!" do
    it "raises an exception without a resource" do
      expect { subject.run!(nil) }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "raises an exception for an invalid resource uri" do
      expect { subject.run!("arn:abcd:efgh") }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "calls docker run with the image name" do
      expect(AwesomeSpawn)
        .to receive(:run!)
        .with("docker", :params => array_including("run", :rm, "hello-world:latest"))
        .and_return(result)
      subject.run!("docker://hello-world:latest")
    end

    it "passes environment variables to docker run" do
      expect(AwesomeSpawn)
        .to receive(:run!)
        .with("docker", :params => array_including("run", :rm, [:e, "FOO=BAR"], "hello-world:latest"))
        .and_return(result)

      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"})
    end

    it "passes a secrets volume to docker run" do
      expect(AwesomeSpawn)
        .to receive(:run!)
        .with("docker", :params => array_including("run", :rm, [:e, "FOO=BAR"], [:v, a_string_including(":/run/secrets")], "hello-world:latest"))
        .and_return(result)

      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"}, {"luggage_password" => "1234"})
    end
  end
end
