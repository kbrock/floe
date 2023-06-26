RSpec.describe Floe::Workflow::Runner::Podman do
  require "securerandom"

  let(:subject)        { described_class.new(runner_options) }
  let(:runner_options) { {} }
  let(:container_id)   { SecureRandom.hex }

  describe "#run_async!" do
    it "raises an exception without a resource" do
      expect { subject.run_async!(nil) }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "raises an exception for an invalid resource uri" do
      expect { subject.run_async!("arn:abcd:efgh") }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "calls docker run with the image name" do
      stub_good_run!("podman", :params => ["run", :detach, "hello-world:latest"], :output => container_id)

      subject.run_async!("docker://hello-world:latest")
    end

    it "passes environment variables to podman run" do
      stub_good_run!("podman", :params => ["run", :detach, [:e, "FOO=BAR"], "hello-world:latest"], :output => container_id)

      subject.run_async!("docker://hello-world:latest", {"FOO" => "BAR"})
    end

    it "passes a secrets volume to podman run" do
      stub_good_run!("podman", :params => ["secret", "create", anything, "-"], :in_data => {"luggage_password" => "12345"}.to_json)
      stub_good_run!("podman", :params => ["run", :detach, [:e, "FOO=BAR"], [:e, a_string_including("_CREDENTIALS=")], [:secret, anything], "hello-world:latest"], :output => container_id)

      subject.run_async!("docker://hello-world:latest", {"FOO" => "BAR"}, {"luggage_password" => "12345"})
    end

    it "deletes the secret if running the container fails" do
      stub_good_run!("podman", :params => ["secret", "create", anything, "-"], :in_data => {"luggage_password" => "12345"}.to_json)
      stub_bad_run!("podman", :params => ["run", :detach, [:e, "FOO=BAR"], [:e, a_string_including("_CREDENTIALS=")], [:secret, anything], "hello-world:latest"])
      stub_good_run!("podman", :params => ["secret", "rm", anything])

      expect { subject.run_async!("docker://hello-world:latest", {"FOO" => "BAR"}, {"luggage_password" => "12345"}) }.to raise_error(AwesomeSpawn::CommandResultError, /podman exit code: 1/)
    end
  end

  describe "#running?" do
    it "retuns true when running" do
      stub_good_run!("podman", :params => ["inspect", container_id], :output => "[{\"State\": {\"Running\": true}}]")
      expect(subject.running?(container_id)).to be_truthy
    end

    it "retuns false when not running" do
      stub_good_run!("podman", :params => ["inspect", container_id], :output => "[{\"State\": {\"Running\": false, \"ExitCode\": 0}}]")
      expect(subject.running?(container_id)).to be_falsey
    end
  end

  describe "#success?" do
    it "retuns true when successful" do
      stub_good_run!("podman", :params => ["inspect", container_id], :output => "[{\"State\": {\"Running\": true, \"ExitCode\": 0}}]")
      expect(subject.success?(container_id)).to be_truthy
    end

    it "retuns false when not successful" do
      stub_good_run!("podman", :params => ["inspect", container_id], :output => "[{\"State\": {\"Running\": false, \"ExitCode\": 1}}]")
      expect(subject.success?(container_id)).to be_falsey
    end
  end

  describe "#output" do
    it "returns log output" do
      stub_good_run!("podman", :params => ["logs", container_id], :output => "hello, world!")
      expect(subject.output(container_id)).to eq("hello, world!")
    end
  end

  describe "#cleanup" do
    it "deletes the container and secret" do
      stub_good_run!("podman", :params => ["secret", "rm", "my-secret"])
      stub_good_run!("podman", :params => ["rm", container_id])

      subject.cleanup(container_id, "my-secret")
    end

    it "doesn't delete the secret if one isn't passed in" do
      stub_good_run!("podman", :params => ["rm", container_id])

      subject.cleanup(container_id, nil)
    end

    it "deletes the secret if deleting the pod fails" do
      stub_good_run!("podman", :params => ["secret", "rm", "my-secret"])
      stub_bad_run!("podman", :params => ["rm", container_id])

      subject.cleanup(container_id, "my-secret")
    end

    context "with docker runner options" do
      context "with --identity" do
        let(:runner_options) { {"identity" => ".ssh/id_rsa.pub"} }

        it "calls docker run with --identity .ssh/id_rsa.pub" do
          stub_good_run!("podman", :params => [[:identity, ".ssh/id_rsa.pub"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --log-level" do
        let(:runner_options) { {"log-level" => "debug"} }

        it "calls docker run with --log-level debug" do
          stub_good_run!("podman", :params => [[:"log-level", "debug"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --network" do
        let(:runner_options) { {"network" => "host"} }

        it "calls docker run with --net host" do
          stub_good_run!("podman", :params => ["run", :rm, [:net, "host"], "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --noout" do
        let(:runner_options) { {"noout" => "true"} }

        it "calls docker run with --noout" do
          stub_good_run!("podman", :params => [:noout, "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --root" do
        let(:runner_options) { {"root" => "/run/containers/storage"} }

        it "calls docker run with --root /run/containers/storage" do
          stub_good_run!("podman", :params => [[:root, "/run/containers/storage"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --runroot" do
        let(:runner_options) { {"runroot" => "/run/containers/runtime"} }

        it "calls docker run with --runroot /run/containers/runtime" do
          stub_good_run!("podman", :params => [[:runroot, "/run/containers/runtime"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --runtime-flag" do
        let(:runner_options) { {"runtime-flag" => "'log debug'"} }

        it "calls docker run with --runtime-flag 'log debug'" do
          stub_good_run!("podman", :params => [[:"runtime-flag", "'log debug'"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --storage-driver" do
        let(:runner_options) { {"storage-driver" => "overlay"} }

        it "calls docker run with --storage-driver overlay" do
          stub_good_run!("podman", :params => [[:"storage-driver", "overlay"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with --storage-opt" do
        let(:runner_options) { {"storage-opt" => "ignore_chown_errors=true"} }

        it "calls docker run with --storage-driver overlay" do
          stub_good_run!("podman", :params => [[:"storage-opt", "ignore_chown_errors=true"], "run", :rm, "hello-world:latest"])

          subject.run!("docker://hello-world:latest")
        end
      end
    end
  end
end
