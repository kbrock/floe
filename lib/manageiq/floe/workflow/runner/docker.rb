module ManageIQ
  module Floe
    class Workflow
      class Runner
        class Docker < ManageIQ::Floe::Workflow::Runner
          def initialize(*)
            require "awesome_spawn"

            super
          end

          def run!(resource, env = {}, secrets = {})
            raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

            image = resource.gsub("docker://", "")

            secrets_file = nil

            if secrets && !secrets.empty?
              require "tempfile"
              secrets_file = Tempfile.new
              secrets_file.write(secrets.to_json)
              secrets_file.flush
            end

            params = ["run", :rm]
            params += env.map { |k, v| [:e, "#{k}=#{v}"] } if env && !env.empty?
            params << [:v, "#{secrets_file.path}:/run/secrets"] if secrets_file
            params << image

            logger.debug("Running docker: #{AwesomeSpawn.build_command_line("docker", params)}")
            result = AwesomeSpawn.run!("docker", :params => params)

            [result.exit_status, result.output]
          ensure
            secrets_file&.close!
          end
        end
      end
    end
  end
end
