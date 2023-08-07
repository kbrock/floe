RSpec.describe Floe::Workflow::Runner::Kubernetes do
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('KUBECONFIG', nil).and_return(nil)
  end

  let(:subject)        { described_class.new(runner_options) }
  let(:runner_options) { {"server" => "https://kubernetes.local:6443", "token" => "my-token"} }

  describe "#run!" do
    let(:kubeclient) { double("Kubeclient::Client") }

    before do
      require "kubeclient"

      allow(Kubeclient::Client).to receive(:new).and_return(kubeclient)
      allow(kubeclient).to receive(:discover)
    end

    it "raises an exception without a resource" do
      expect { subject.run!(nil) }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "raises an exception for an invalid resource uri" do
      expect { subject.run!("arn:abcd:efgh") }.to raise_error(ArgumentError, "Invalid resource")
    end

    it "calls kubectl run with the image name" do
      expected_pod_spec = hash_including(:kind => "Pod", :apiVersion => "v1", :metadata => {:name => a_string_including("hello-world-"), :namespace => "default"})

      expect(kubeclient).to receive(:create_pod).with(expected_pod_spec)
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").and_return({"status" => {"phase" => "Running"}})
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").twice.and_return({"status" => {"phase" => "Succeeded"}})
      expect(kubeclient).to receive(:get_pod_log).with(a_string_including("hello-world-"), "default").and_return(RestClient::Response.new("hello, world!"))
      expect(kubeclient).to receive(:delete_pod).with(a_string_including("hello-world-"), "default")

      expect(subject).to receive(:sleep).with(1)
      subject.run!("docker://hello-world:latest")
    end

    it "doesn't create a secret if Credentials is nil" do
      expected_pod_spec = hash_including(:kind => "Pod", :apiVersion => "v1", :metadata => {:name => a_string_including("hello-world-"), :namespace => "default"})

      expect(subject).not_to receive(:create_secret!)
      expect(kubeclient).to receive(:create_pod).with(expected_pod_spec)
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").and_return({"status" => {"phase" => "Running"}})
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").twice.and_return({"status" => {"phase" => "Succeeded"}})
      expect(kubeclient).to receive(:get_pod_log).with(a_string_including("hello-world-"), "default").and_return(RestClient::Response.new("hello, world!"))
      expect(kubeclient).to receive(:delete_pod).with(a_string_including("hello-world-"), "default")

      expect(subject).to receive(:sleep).with(1)
      subject.run!("docker://hello-world:latest", {}, nil)
    end

    it "passes environment variables to kubectl run" do
      expected_pod_spec = hash_including(
        :spec => hash_including(
          :containers => [hash_including(:env => [{:name => "FOO", :value => "BAR"}])]
        )
      )

      expect(kubeclient).to receive(:create_pod).with(expected_pod_spec)
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").and_return({"status" => {"phase" => "Running"}})
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").twice.and_return({"status" => {"phase" => "Succeeded"}})
      expect(kubeclient).to receive(:get_pod_log).with(a_string_including("hello-world-"), "default").and_return(RestClient::Response.new("hello, world!"))
      expect(kubeclient).to receive(:delete_pod).with(a_string_including("hello-world-"), "default")

      expect(subject).to receive(:sleep).with(1)
      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"})
    end

    it "passes integer environment variables to kubectl run as strings" do
      expected_pod_spec = hash_including(
        :spec => hash_including(
          :containers => [hash_including(:env => [{:name => "FOO", :value => "1"}])]
        )
      )

      expect(kubeclient).to receive(:create_pod).with(expected_pod_spec)
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").and_return({"status" => {"phase" => "Running"}})
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").twice.and_return({"status" => {"phase" => "Succeeded"}})
      expect(kubeclient).to receive(:get_pod_log).with(a_string_including("hello-world-"), "default").and_return(RestClient::Response.new("hello, world!"))
      expect(kubeclient).to receive(:delete_pod).with(a_string_including("hello-world-"), "default")

      expect(subject).to receive(:sleep).with(1)
      subject.run!("docker://hello-world:latest", {"FOO" => 1})
    end

    it "passes a secrets volume to kubectl run" do
      expected_pod_spec = hash_including(
        :kind       => "Pod",
        :apiVersion => "v1",
        :metadata   => {:name => a_string_including("hello-world-"), :namespace => "default"},
        :spec       => hash_including(
          :volumes    => [{:name => "secret-volume", :secret => {:secretName => anything}}],
          :containers => [
            hash_including(
              :env          => [
                {:name => "FOO",     :value => "BAR"},
                {:name => "SECRETS", :value => a_string_including("/run/secrets/")}
              ],
              :volumeMounts => [
                {
                  :mountPath => a_string_including("/run/secrets/"),
                  :name      => "secret-volume",
                  :readOnly  => true
                }
              ]
            )
          ]
        )
      )

      expect(kubeclient).to receive(:create_secret).with(hash_including(:kind => "Secret", :type => "Opaque"))
      expect(kubeclient).to receive(:create_pod).with(expected_pod_spec)
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").and_return({"status" => {"phase" => "Running"}})
      expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), "default").twice.and_return({"status" => {"phase" => "Succeeded"}})
      expect(kubeclient).to receive(:get_pod_log).with(a_string_including("hello-world-"), "default").and_return(RestClient::Response.new("hello, world!"))
      expect(kubeclient).to receive(:delete_pod).with(a_string_including("hello-world-"), "default")
      expect(kubeclient).to receive(:delete_secret).with(anything, "default")

      expect(subject).to receive(:sleep).with(1)
      subject.run!("docker://hello-world:latest", {"FOO" => "BAR"}, {"luggage_password" => "12345"})
    end

    context "with an alternate namespace" do
      let(:namespace)      { "my-project" }
      let(:runner_options) { {"server" => "https://kubernetes.local:6443", "token" => "my-token", "namespace" => namespace} }

      it "calls kubectl run with the image name" do
        expected_pod_spec = hash_including(:kind => "Pod", :apiVersion => "v1", :metadata => {:name => a_string_including("hello-world-"), :namespace => namespace})

        expect(kubeclient).to receive(:create_pod).with(expected_pod_spec)
        expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), namespace).and_return({"status" => {"phase" => "Running"}})
        expect(kubeclient).to receive(:get_pod).with(a_string_including("hello-world-"), namespace).twice.and_return({"status" => {"phase" => "Succeeded"}})
        expect(kubeclient).to receive(:get_pod_log).with(a_string_including("hello-world-"), namespace).and_return(RestClient::Response.new("hello, world!"))
        expect(kubeclient).to receive(:delete_pod).with(a_string_including("hello-world-"), namespace)

        expect(subject).to receive(:sleep).with(1)
        subject.run!("docker://hello-world:latest")
      end
    end

    context "without a kubeconfig file or server+token" do
      let(:runner_options) { {} }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(File.join(Dir.home, ".kube", "config")).and_return(false)
      end

      it "raises an exception" do
        expect { subject.run!("docker://hello-world:latest") }.to raise_error(ArgumentError, /Missing connections options/)
      end
    end

    context "with a kubeconfig file" do
      let(:kubeconfig_path) { File.join(Dir.home, ".kube", "config") }
      let(:kubeconfig) do
        {
          "apiVersion"      => "v1",
          "clusters"        => [
            {
              "cluster" => {"server" => "https://kubernetes.local:6443"},
              "name"    => "default"
            }
          ],
          "contexts"        => [
            {"context" => {"cluster" => "default", "user" => "default"}, "name" => "default"},
            {"context" => {"cluster" => "default", "user" => "foo"},     "name" => "foo"}
          ],
          "current-context" => "default",
          "kind"            => "Config",
          "preferences"     => {},
          "users"           => [
            {
              "name" => "default",
              "user" => {
                "token" => "my-token"
              }
            },
            {
              "name" => "foo",
              "user" => {
                "token" => "foo"
              }
            }
          ]
        }.to_yaml
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:read).and_call_original

        allow(File).to receive(:exist?).with(kubeconfig_path).and_return(true)
        allow(File).to receive(:read).with(kubeconfig_path).and_return(kubeconfig)

        allow(kubeclient).to receive(:create_pod)
        allow(kubeclient).to receive(:get_pod).twice.and_return({"status" => {"phase" => "Succeeded"}})
        allow(kubeclient).to receive(:get_pod_log).and_return(RestClient::Response.new("hello, world!"))
        allow(kubeclient).to receive(:delete_pod)
      end

      context "with no runner options passed" do
        let(:runner_options) { {} }

        it "uses the kubeconfig values" do
          expect(Kubeclient::Client).to receive(:new).with("https://kubernetes.local:6443", "v1", :ssl_options => {:verify_ssl => OpenSSL::SSL::VERIFY_PEER}, :auth_options => {:bearer_token => "my-token"}).and_return(kubeclient)

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with server+token passed as runner options" do
        let(:runner_options) { {"server" => "https://my-other-kubernetes.local:6443", "token" => "my-other-token"} }

        it "prefers the provided options values over the kubeconfig file" do
          expect(Kubeclient::Client).to receive(:new).with("https://my-other-kubernetes.local:6443", "v1", :ssl_options => {:verify_ssl => OpenSSL::SSL::VERIFY_PEER}, :auth_options => {:bearer_token => "my-other-token"})

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with an alternate kubeconfig file passed as an option" do
        let(:kubeconfig_path) { "/etc/kube/config" }
        let(:runner_options)  { {"kubeconfig" => kubeconfig_path} }

        it "uses the kubeconfig values" do
          expect(Kubeclient::Client).to receive(:new).with("https://kubernetes.local:6443", "v1", :ssl_options => {:verify_ssl => OpenSSL::SSL::VERIFY_PEER}, :auth_options => {:bearer_token => "my-token"})

          subject.run!("docker://hello-world:latest")
        end
      end

      context "with an alternate context passed" do
        let(:runner_options) { {"kubeconfig_context" => "foo"} }

        it "uses the values from the kubeconfig context" do
          expect(Kubeclient::Client).to receive(:new).with("https://kubernetes.local:6443", "v1", :ssl_options => {:verify_ssl => OpenSSL::SSL::VERIFY_PEER}, :auth_options => {:bearer_token => "foo"})

          subject.run!("docker://hello-world:latest")
        end
      end
    end

    context "with a token" do
      let(:token)          { "my-token" }
      let(:runner_options) { {"server" => "https://kubernetes.local:6443", "token" => token} }

      it "calls kubectl run with the image name" do
        expect(Kubeclient::Client).to receive(:new).with("https://kubernetes.local:6443", "v1", :ssl_options => {:verify_ssl => OpenSSL::SSL::VERIFY_PEER}, :auth_options => {:bearer_token => token}).and_return(kubeclient)

        allow(kubeclient).to receive(:create_pod)
        allow(kubeclient).to receive(:get_pod).twice.and_return({"status" => {"phase" => "Succeeded"}})
        allow(kubeclient).to receive(:get_pod_log).and_return(RestClient::Response.new("hello, world!"))
        allow(kubeclient).to receive(:delete_pod)

        subject.run!("docker://hello-world:latest")
      end
    end

    context "with a token file" do
      let(:token)          { "my-token" }
      let(:token_file)     { "/path/to/my-token" }
      let(:runner_options) { {"server" => "https://kubernetes.local:6443", "token_file" => token_file} }

      it "calls kubectl run with the image name" do
        allow(File).to receive(:read).and_call_original
        expect(File).to receive(:read).with(token_file).and_return(token)

        expect(Kubeclient::Client).to receive(:new).with("https://kubernetes.local:6443", "v1", :ssl_options => {:verify_ssl => OpenSSL::SSL::VERIFY_PEER}, :auth_options => {:bearer_token => token}).and_return(kubeclient)

        allow(kubeclient).to receive(:create_pod)
        allow(kubeclient).to receive(:get_pod).twice.and_return({"status" => {"phase" => "Succeeded"}})
        allow(kubeclient).to receive(:get_pod_log).and_return(RestClient::Response.new("hello, world!"))
        allow(kubeclient).to receive(:delete_pod)

        subject.run!("docker://hello-world:latest")
      end
    end
  end
end
