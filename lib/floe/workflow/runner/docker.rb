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

          secrets_file = nil
          if secrets && !secrets.empty?
            secrets_file = create_secret(secrets)
            env["_CREDENTIALS"] = "/run/secrets"
          end

          output = run_container(image, env, secrets_file)

          [0, output]
        ensure
          secrets_file&.close!
        end

        def run_async!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image = resource.sub("docker://", "")

          secrets_file = nil
          if secrets && !secrets.empty?
            secrets_file = create_secret(secrets)
            env["_CREDENTIALS"] = "/run/secrets"
          end

          begin
            container_id = run_container(image, env, secrets_file, :detached => true)
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
          inspect_container(container_id).first.dig("State", "Running")
        end

        def success?(container_id)
          inspect_container(container_id).first.dig("State", "ExitCode") == 0
        end

        def output(container_id)
          docker!("logs", container_id).output
        end

        private

        attr_reader :network

        def run_container(image, env, secrets_file, detached: false)
          params  = ["run"]
          params << (detached ? :detach : :rm)
          params += env.map { |k, v| [:e, "#{k}=#{v}"] }
          params << [:net, "host"] if @network == "host"
          params << [:v, "#{secrets_file.path}:/run/secrets:z"] if secrets_file
          params << image

          logger.debug("Running docker: #{AwesomeSpawn.build_command_line("docker", params)}")

          result = docker!(*params)
          result.output
        end

        def inspect_container(container_id)
          JSON.parse(docker!("inspect", container_id).output)
        end

        def delete_container(container_id)
          docker!("rm", container_id)
        rescue
          nil
        end

        def create_secret(secrets)
          secrets_file = Tempfile.new
          secrets_file.write(secrets.to_json)
          secrets_file.flush
          secrets_file
        end

        def docker!(*params, **kwargs)
          AwesomeSpawn.run!("docker", :params => params, **kwargs)
        end
      end
    end
  end
end
