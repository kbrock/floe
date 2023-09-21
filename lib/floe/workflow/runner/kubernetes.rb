# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      class Kubernetes < Floe::Workflow::Runner
        TOKEN_FILE   = "/run/secrets/kubernetes.io/serviceaccount/token"
        CA_CERT_FILE = "/run/secrets/kubernetes.io/serviceaccount/ca.crt"

        def initialize(options = {})
          require "awesome_spawn"
          require "securerandom"
          require "base64"
          require "kubeclient"
          require "yaml"

          @kubeconfig_file    = ENV.fetch("KUBECONFIG", nil) || options.fetch("kubeconfig", File.join(Dir.home, ".kube", "config"))
          @kubeconfig_context = options["kubeconfig_context"]

          @token   = options["token"]
          @token ||= File.read(options["token_file"]) if options.key?("token_file")
          @token ||= File.read(TOKEN_FILE) if File.exist?(TOKEN_FILE)

          @server   = options["server"]
          @server ||= URI::HTTPS.build(:host => ENV.fetch("KUBERNETES_SERVICE_HOST"), :port => ENV.fetch("KUBERNETES_SERVICE_PORT", 6443)) if ENV.key?("KUBERNETES_SERVICE_HOST")

          @ca_file   = options["ca_file"]
          @ca_file ||= CA_CERT_FILE if File.exist?(CA_CERT_FILE)

          @verify_ssl = options["verify_ssl"] == "false" ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER

          if server.nil? && token.nil? && !File.exist?(kubeconfig_file)
            raise ArgumentError, "Missing connections options, provide a kubeconfig file or pass server and token via --docker-runner-options"
          end

          @namespace = options.fetch("namespace", "default")

          super
        end

        def run!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image  = resource.sub("docker://", "")
          name   = pod_name(image)
          secret = create_secret!(secrets) if secrets && !secrets.empty?

          begin
            runner_context = {"container_ref" => name}

            create_pod!(name, image, env, secret)
            loop do
              case pod_info(name).dig("status", "phase")
              when "Pending", "Running"
                sleep(1)
              else # also "Succeeded"
                runner_context["exit_code"] = 0
                output(runner_context)
                break
              end
            end

            runner_context
          ensure
            cleanup({"container_ref" => name, "secrets_ref" => secret})
          end
        end

        def run_async!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image  = resource.sub("docker://", "")
          name   = pod_name(image)
          secret = create_secret!(secrets) if secrets && !secrets.empty?

          runner_context = {"container_ref" => name, "secrets_ref" => secret}

          begin
            create_pod!(name, image, env, secret)
          rescue
            cleanup(runner_context)
            raise
          end

          runner_context
        end

        def status!(runner_context)
          runner_context["container_state"] = pod_info(runner_context["container_ref"])["status"]
        end

        def running?(runner_context)
          %w[Pending Running].include?(runner_context.dig("container_state", "phase"))
        end

        def success?(runner_context)
          runner_context.dig("container_state", "phase") == "Succeeded"
        end

        def output(runner_context)
          output = kubeclient.get_pod_log(runner_context["container_ref"], namespace).body
          runner_context["output"] = output
        end

        def cleanup(runner_context)
          pod, secret = runner_context.values_at("container_ref", "secrets_ref")

          delete_pod(pod)       if pod
          delete_secret(secret) if secret
        end

        private

        attr_reader :ca_file, :kubeconfig_file, :kubeconfig_context, :namespace, :server, :token, :verify_ssl

        def pod_info(pod_name)
          kubeclient.get_pod(pod_name, namespace)
        end

        def container_name(image)
          image.match(%r{^(?<repository>.+/)?(?<image>.+):(?<tag>.+)$})&.named_captures&.dig("image")
        end

        def pod_name(image)
          container_short_name = container_name(image)
          raise ArgumentError, "Invalid docker image [#{image}]" if container_short_name.nil?

          "#{container_short_name}-#{SecureRandom.uuid}"
        end

        def pod_spec(name, image, env, secret = nil)
          spec = {
            :kind       => "Pod",
            :apiVersion => "v1",
            :metadata   => {
              :name      => name,
              :namespace => namespace
            },
            :spec       => {
              :containers    => [
                {
                  :name  => container_name(image),
                  :image => image,
                  :env   => env.map { |k, v| {:name => k, :value => v.to_s} }
                }
              ],
              :restartPolicy => "Never"
            }
          }

          if secret
            spec[:spec][:volumes] = [
              {
                :name   => "secret-volume",
                :secret => {:secretName => secret}
              }
            ]

            spec[:spec][:containers][0][:env] << {
              :name  => "_CREDENTIALS",
              :value => "/run/secrets/#{secret}/secret"
            }

            spec[:spec][:containers][0][:volumeMounts] = [
              {
                :name      => "secret-volume",
                :mountPath => "/run/secrets/#{secret}",
                :readOnly  => true
              }
            ]
          end

          spec
        end

        def create_pod!(name, image, env, secret = nil)
          kubeclient.create_pod(pod_spec(name, image, env, secret))
        end

        def delete_pod!(name)
          kubeclient.delete_pod(name, namespace)
        end

        def delete_pod(name)
          delete_pod!(name)
        rescue
          nil
        end

        def create_secret!(secrets)
          secret_name = SecureRandom.uuid

          secret_config = {
            :kind       => "Secret",
            :apiVersion => "v1",
            :metadata   => {
              :name      => secret_name,
              :namespace => namespace
            },
            :data       => {
              :secret => Base64.urlsafe_encode64(secrets.to_json)
            },
            :type       => "Opaque"
          }

          kubeclient.create_secret(secret_config)

          secret_name
        end

        def delete_secret!(secret_name)
          kubeclient.delete_secret(secret_name, namespace)
        end

        def delete_secret(name)
          delete_secret!(name)
        rescue
          nil
        end

        def kubeclient
          return @kubeclient unless @kubeclient.nil?

          if server && token
            api_endpoint = server
            auth_options = {:bearer_token => token}
            ssl_options  = {:verify_ssl => verify_ssl}
            ssl_options[:ca_file] = ca_file if ca_file
          else
            context = kubeconfig&.context(kubeconfig_context)
            raise ArgumentError, "Missing connections options, provide a kubeconfig file or pass server and token via --docker-runner-options" if context.nil?

            api_endpoint = context.api_endpoint
            auth_options = context.auth_options
            ssl_options  = context.ssl_options
          end

          @kubeclient = Kubeclient::Client.new(api_endpoint, "v1", :ssl_options => ssl_options, :auth_options => auth_options).tap(&:discover)
        end

        def kubeconfig
          return if kubeconfig_file.nil? || !File.exist?(kubeconfig_file)

          Kubeclient::Config.read(kubeconfig_file)
        end
      end
    end
  end
end
