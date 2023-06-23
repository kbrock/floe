# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      class Kubernetes < Floe::Workflow::Runner
        attr_reader :namespace, :server, :token

        def initialize(options = {})
          require "awesome_spawn"
          require "securerandom"
          require "base64"
          require "yaml"

          @namespace = options.fetch("namespace", "default")
          @server    = options.fetch("server", nil)
          @token     = options.fetch("token", nil)
          @token   ||= File.read(options["token_file"]) if options.key?("token_file")

          super
        end

        def run!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image     = resource.sub("docker://", "")
          name      = pod_name(image)
          secret    = create_secret!(secrets) unless secrets&.empty?
          overrides = pod_spec(image, env, secret)

          result = kubectl_run!(image, name, overrides)

          # Kubectl prints that the pod was deleted, strip this from the output
          output = result.output.gsub(/pod "#{name}" deleted/, "")

          [result.exit_status, output]
        ensure
          delete_secret!(secret) if secret
        end

        private

        def container_name(image)
          image.match(%r{^(?<repository>.+/)?(?<image>.+):(?<tag>.+)$})&.named_captures&.dig("image")
        end

        def pod_name(image)
          container_short_name = container_name(image)
          raise ArgumentError, "Invalid docker image [#{image}]" if container_short_name.nil?

          "#{container_short_name}-#{SecureRandom.uuid}"
        end

        def pod_spec(image, env, secret = nil)
          container_spec = {
            "name"  => container_name(image),
            "image" => image,
            "env"   => env.to_h.map { |k, v| {"name" => k, "value" => v.to_s} }
          }

          spec = {"spec" => {"containers" => [container_spec]}}

          if secret
            spec["spec"]["volumes"] = [{"name" => "secret-volume", "secret" => {"secretName" => secret}}]
            container_spec["env"] << {"name" => "SECRETS", "value" => "/run/secrets/#{secret}/secret"}
            container_spec["volumeMounts"] = [
              {
                "name"      => "secret-volume",
                "mountPath" => "/run/secrets/#{secret}",
                "readOnly"  => true
              }
            ]
          end

          spec
        end

        def create_secret!(secrets)
          secret_name = SecureRandom.uuid

          secret_yaml = {
            "kind"       => "Secret",
            "apiVersion" => "v1",
            "metadata"   => {
              "name"      => secret_name,
              "namespace" => namespace
            },
            "data"       => {
              "secret" => Base64.urlsafe_encode64(secrets.to_json)
            },
            "type"       => "Opaque"
          }.to_yaml

          kubectl!("create", "-f", "-", :in_data => secret_yaml)

          secret_name
        end

        def delete_secret!(secret_name)
          kubectl!("delete", "secret", secret_name, [:namespace, namespace])
        end

        def kubectl!(*params, **kwargs)
          params.unshift([:token, token])   if token
          params.unshift([:server, server]) if server

          AwesomeSpawn.run!("kubectl", :params => params, **kwargs)
        end

        def kubectl_run!(image, name, overrides = nil)
          params = [
            "run", :rm, :attach, [:image, image], [:restart, "Never"], [:namespace, namespace], name
          ]

          params << "--overrides=#{overrides.to_json}" if overrides

          logger.debug("Running kubectl: #{AwesomeSpawn.build_command_line("kubectl", params)}")

          kubectl!(*params)
        end
      end
    end
  end
end
