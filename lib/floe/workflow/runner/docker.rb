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

          {"exit_code" => 0, "output" => output}
        ensure
          cleanup({"secrets_ref" => secrets_file})
        end

        def run_async!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image = resource.sub("docker://", "")

          runner_context = {}

          if secrets && !secrets.empty?
            runner_context["secrets_ref"] = create_secret(secrets)
            env["_CREDENTIALS"] = "/run/secrets"
          end

          begin
            runner_context["container_ref"] = run_container(image, env, runner_context["secrets_ref"], :detached => true)
          rescue
            cleanup(runner_context)
            raise
          end

          runner_context
        end

        def cleanup(runner_context)
          container_id, secrets_file = runner_context.values_at("container_ref", "secrets_ref")

          delete_container(container_id) if container_id
          File.unlink(secrets_file)      if secrets_file && File.exist?(secrets_file)
        end

        def status!(runner_context)
          runner_context["container_state"] = inspect_container(runner_context["container_ref"]).first&.dig("State")
        end

        def running?(runner_context)
          runner_context.dig("container_state", "Running")
        end

        def success?(runner_context)
          runner_context.dig("container_state", "ExitCode") == 0
        end

        def output(runner_context)
          output = docker!("logs", runner_context["container_ref"]).output
          runner_context["output"] = output
        end

        private

        attr_reader :network

        def run_container(image, env, secrets_file, detached: false)
          params  = ["run"]
          params << (detached ? :detach : :rm)
          params += env.map { |k, v| [:e, "#{k}=#{v}"] }
          params << [:net, "host"] if @network == "host"
          params << [:v, "#{secrets_file}:/run/secrets:z"] if secrets_file
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
          secrets_file.close
          secrets_file.path
        end

        def docker!(*params, **kwargs)
          AwesomeSpawn.run!("docker", :params => params, **kwargs)
        end
      end
    end
  end
end
