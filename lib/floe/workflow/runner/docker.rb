# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      class Docker < Floe::Workflow::Runner
        def initialize(options = {})
          require "awesome_spawn"
          require "tempfile"

          super

          @network = options.fetch("network", "bridge")
        end

        def run!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image = resource.sub("docker://", "")

          params  = ["run", :rm]
          params += [[:net, "host"]] if network == "host"
          params += env.map { |k, v| [:e, "#{k}=#{v}"] } if env

          secrets_file = nil

          if secrets && !secrets.empty?
            secrets_file = Tempfile.new
            secrets_file.write(secrets.to_json)
            secrets_file.flush

            params << [:e, "_CREDENTIALS=/run/secrets"]
            params << [:v, "#{secrets_file.path}:/run/secrets:z"]
          end

          params << image

          logger.debug("Running docker: #{AwesomeSpawn.build_command_line("docker", params)}")
          result = AwesomeSpawn.run!("docker", :params => params)

          [result.exit_status, result.output]
        ensure
          secrets_file&.close!
        end

        private

        attr_reader :network
      end
    end
  end
end
