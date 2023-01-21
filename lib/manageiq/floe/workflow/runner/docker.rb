module ManageIQ
  module Floe
    class Workflow
      class Runner
        class Docker < ManageIQ::Floe::Workflow::Runner
          def run!(resource, env = {}, _secrets = {})
            raise ArgumentError, "Invalid resource" unless resource.start_with?("docker://")

            image = resource.gsub("docker://", "")

            params = ["run", "--rm"]
            params += env.map { |k, v| [:e, "#{k}=#{v}"] } unless env.empty?
            params << image

            require "awesome_spawn"
            logger.debug("Running docker: #{AwesomeSpawn.build_command_line("docker", params)}")
            result = AwesomeSpawn.run!("docker", :params => params)

            [result.exit_status, result.output]
          end
        end
      end
    end
  end
end
