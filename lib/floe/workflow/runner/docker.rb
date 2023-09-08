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

        def run_async!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image = resource.sub("docker://", "")

          params = ["run", :detach]
          params += [[:net, "host"]] if network == "host"
          params += env.map { |k, v| [:e, "#{k}=#{v}"] } if env

          secrets_file = nil

          if secrets && !secrets.empty?
            secrets_file = Tempfile.new
            secrets_file.write(secrets.to_json)
            secrets_file.flush

            params << [:e, "SECRETS=/run/secrets"]
            params << [:v, "#{secrets_file.path}:/run/secrets:z"]
          end

          params << image

          logger.debug("Running docker: #{AwesomeSpawn.build_command_line("docker", params)}")

          begin
            container_id = docker!(*params).output
          rescue
            cleanup(container_id, secrets_file)
            raise
          end

          [container_id, secrets_file]
        end

        def cleanup(container_id, secrets_file)
          delete_container(container_id) if container_id
          secrets_file&.close!
        end

        def running?(container_id)
          JSON.parse(docker!("inspect", container_id).output).first.dig("State", "Running")
        end

        def success?(container_id)
          JSON.parse(docker!("inspect", container_id).output).first.dig("State", "ExitCode") == 0
        end

        def output(container_id)
          docker!("logs", container_id).output
        end

        private

        attr_reader :network

        def delete_container(container_id)
          docker!("rm", container_id)
        rescue
          nil
        end

        def docker!(*params, **kwargs)
          AwesomeSpawn.run!("docker", :params => params, **kwargs)
        end
      end
    end
  end
end
