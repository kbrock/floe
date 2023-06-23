RSpec.describe Floe::Workflow::Runner::Kubernetes do
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

    it "doesn't create a secret if Credentials is nil" do
      expect(subject).not_to receive(:create_secret!)
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

      subject.run!("docker://hello-world:latest", {}, nil)
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

    it "passes integer environment variables to kubectl run as strings" do
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
          a_string_including("\"env\":[{\"name\":\"FOO\",\"value\":\"1\"}]")
        ]
      )

      subject.run!("docker://hello-world:latest", {"FOO" => 1})
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

    context "with an alternate namespace" do
      let(:namespace) { "my-project" }
      let(:subject)   { described_class.new("namespace" => namespace) }

      it "calls kubectl run with the image name" do
        stub_good_run!(
          "kubectl",
          :params => [
            "run",
            :rm,
            :attach,
            [:image, "hello-world:latest"],
            [:restart, "Never"],
            [:namespace, namespace],
            a_string_including("hello-world-"),
            a_string_including("--overrides")
          ]
        )

        subject.run!("docker://hello-world:latest")
      end
    end

    context "with a token" do
      let(:token)   { "my-token" }
      let(:subject) { described_class.new("token" => token) }

      it "calls kubectl run with the image name" do
        stub_good_run!(
          "kubectl",
          :params => [
            [:token, token],
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
    end

    context "with a token file" do
      let(:token)      { "my-token" }
      let(:token_file) { "/path/to/my-token" }
      let(:subject)    { described_class.new("token_file" => token_file) }

      it "calls kubectl run with the image name" do
        expect(File).to receive(:read).with(token_file).and_return(token)

        stub_good_run!(
          "kubectl",
          :params => [
            [:token, token],
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
    end
  end
end
