module ManageIQ
  module Floe
    class Workflow
      class Runner
        class Kubernetes < ManageIQ::Floe::Workflow::Runner
          attr_reader :namespace

          def initialize(*)
            require "awesome_spawn"
            require "securerandom"

            @namespace = "default"

            super
          end

          def run!(resource, env = {}, secrets = {})
            raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

            image = resource.sub("docker://", "")

            name = pod_name(image)
            params = ["run", :rm, :attach, [:image, image], [:restart, "Never"], [:namespace, namespace], name]

            if secrets && !secrets.empty?
              secret_name = create_secret!(secrets)
              container_overrides = {
                "spec" => {
                  "containers" => [
                    {
                      "name" => container_name(image),
                      "image" => image,
                      "env" => [
                        {
                          "name" => "SECRETS",
                          "value" => "/run/secrets/#{secret_name}/secret"
                        }
                      ],
                      "volumeMounts" => [
                        {
                          "name" => "secret-volume",
                          "mountPath" => "/run/secrets/#{secret_name}",
                          "readOnly" => true
                        }
                      ]
                    }
                  ],
                  "volumes"    => [
                    {
                      "name"   => "secret-volume",
                      "secret" => {
                        "secretName" => secret_name
                      }
                    }
                  ]
                }
              }

              params << "--overrides=#{container_overrides.to_json}"
            end

            params += env.map { |k, v| [:env, "#{k}=#{v}"] } if env

            logger.debug("Running kubectl: #{AwesomeSpawn.build_command_line("kubectl", params)}")
            result = AwesomeSpawn.run!("kubectl", :params => params)

            # Kubectl prints that the pod was deleted, strip this from the output
            output = result.output.gsub(/pod \"#{name}\" deleted/, "")

            [result.exit_status, output]
          ensure
            delete_secret!(secret_name) if secret_name
          end

          private

          def container_name(image)
            image.match(%r{^(?<repository>.+\/)?(?<image>.+):(?<tag>.+)$})&.named_captures&.dig("image")
          end

          def pod_name(image)
            container_short_name = container_name(image)
            raise ArgumentError, "Invalid docker image [#{image}]" if container_short_name.nil?

            "#{container_short_name}-#{SecureRandom.uuid}"
          end

          def create_secret!(secrets)
            secret_name = SecureRandom.uuid
            params = ["create", "secret", "generic", secret_name, [:namespace, namespace]]
            params << "--from-literal=secret=#{secrets.to_json}"

            AwesomeSpawn.run!("kubectl", :params => params)

            secret_name
          end

          def delete_secret!(secret_name)
            AwesomeSpawn.run!("kubectl", :params => ["delete", "secret", secret_name, [:namespace, namespace]])
          end
        end
      end
    end
  end
end
