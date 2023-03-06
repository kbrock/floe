module ManageIQ
  module Floe
    class Workflow
      class Runner
        class Kubernetes < ManageIQ::Floe::Workflow::Runner
          def initialize(*)
            require "awesome_spawn"
            require "securerandom"

            super
          end

          def run!(resource, env = {}, secrets = {})
            raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

            image = resource.sub("docker://", "")

            name = pod_name(image)
            params = ["run", :rm, :attach, [:image, image], [:restart, "Never"], name]

            if secrets && !secrets.empty?
              secret_name = create_secret!(secrets)
              #params << [:env, "SECRETS=/TODO"]
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

          def pod_name(image)
            image_name = image.match(%r{^(?<repository>.+\/)?(?<image>.+):(?<tag>.+)$})&.named_captures&.dig("image")
            raise ArgumentError, "Invalid docker image [#{image}]" if image_name.nil?

            "#{image_name}-#{SecureRandom.uuid}"
          end

          def create_secret!(secrets)
            secret_name = SecureRandom.uuid
            params = ["create", "secret", "generic", secret_name]
            secrets.each { |key, value| params << "--from-literal=#{key}=#{value}" }

            AwesomeSpawn.run!("kubectl", :params => params)

            secret_name
          end

          def delete_secret!(secret_name)
            AwesomeSpawn.run!("kubectl", :params => ["delete", "secret", secret_name])
          end
        end
      end
    end
  end
end
