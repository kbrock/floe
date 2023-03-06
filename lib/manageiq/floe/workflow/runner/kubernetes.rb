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
            params += env.map { |k, v| [:env, "#{k}=#{v}"] } if env

            # TODO: Secrets
            #if secrets && !secrets.empty?
            #  params << [:env, "SECRETS=/TODO"]
            #  params << [:overrides, {"spec" => {"containers" => {"env" => [{"name" => "SECRETS", "valueFrom" => {"secretKeyRef" => {"name" => "SECRET_NAME", "key" => "SECRET_KEY"}}}]}}}.to_json]
            #end

            logger.debug("Running kubectl: #{AwesomeSpawn.build_command_line("kubectl", params)}")
            result = AwesomeSpawn.run!("kubectl", :params => params)

            # Kubectl prints that the pod was deleted, strip this from the output
            output = result.output.gsub(/pod \"#{name}\" deleted/, "")

            [result.exit_status, output]
          end

          private

          def pod_name(image)
            image_name = image.match(%r{^(?<repository>.+\/)?(?<image>.+):(?<tag>.+)$})&.named_captures&.dig("image")
            raise ArgumentError, "Invalid docker image [#{image}]" if image_name.nil?

            "#{image_name}-#{SecureRandom.uuid}"
          end
        end
      end
    end
  end
end
