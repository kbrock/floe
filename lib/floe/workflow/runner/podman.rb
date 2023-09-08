# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      class Podman < Floe::Workflow::Runner
        def initialize(options = {})
          require "awesome_spawn"
          require "securerandom"

          super

          @identity        = options["identity"]
          @log_level       = options["log-level"]
          @network         = options["network"]
          @noout           = options["noout"].to_s == "true" if options.key?("noout")
          @root            = options["root"]
          @runroot         = options["runroot"]
          @runtime         = options["runtime"]
          @runtime_flag    = options["runtime-flag"]
          @storage_driver  = options["storage-driver"]
          @storage_opt     = options["storage-opt"]
          @syslog          = options["syslog"].to_s == "true" if options.key?("syslog")
          @tmpdir          = options["tmpdir"]
          @transient_store = !!options["transient-store"] if options.key?("transient-store")
          @volumepath      = options["volumepath"]
        end

        def run!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image = resource.sub("docker://", "")

          if secrets && !secrets.empty?
            secret = create_secret(secrets)
            env["_CREDENTIALS"] = "/run/secrets/#{secret}"
          end

          output = run_container(image, env, secret)

          [0, output]
        ensure
          delete_secret(secret) if secret
        end

        def run_async!(resource, env = {}, secrets = {})
          raise ArgumentError, "Invalid resource" unless resource&.start_with?("docker://")

          image = resource.sub("docker://", "")

          if secrets && !secrets.empty?
            secret = create_secret(secrets)
            env["_CREDENTIALS"] = "/run/secrets/#{secret}"
          end

          begin
            container_id = run_container(image, env, secret, :detached => true)
          rescue
            cleanup(container_id, secret)
            raise
          end

          [container_id, secret]
        end

        def cleanup(container_id, secret_guid)
          delete_container(container_id) if container_id
          delete_secret(secret_guid)     if secret_guid
        end

        def running?(container_id)
          inspect_container(container_id).first.dig("State", "Running")
        end

        def success?(container_id)
          inspect_container(container_id).first.dig("State", "ExitCode") == 0
        end

        def output(container_id)
          podman!("logs", container_id).output
        end

        private

        def run_container(image, env, secret, detached: false)
          params  = ["run"]
          params << (detached ? :detach : :rm)
          params += env.map { |k, v| [:e, "#{k}=#{v}"] }
          params << [:net, "host"] if @network == "host"
          params << [:secret, secret] if secret
          params << image

          logger.debug("Running podman: #{AwesomeSpawn.build_command_line("podman", params)}")

          result = podman!(*params)
          result.output
        end

        def inspect_container(container_id)
          JSON.parse(podman!("inspect", container_id).output)
        end

        def delete_container(container_id)
          podman!("rm", container_id)
        rescue
          nil
        end

        def create_secret(secrets)
          secret_guid = SecureRandom.uuid
          podman!("secret", "create", secret_guid, "-", :in_data => secrets.to_json)
          secret_guid
        end

        def delete_secret(secret_guid)
          podman!("secret", "rm", secret_guid)
        rescue
          nil
        end

        def podman!(*args, **kwargs)
          params = podman_global_options + args

          AwesomeSpawn.run!("podman", :params => params, **kwargs)
        end

        def podman_global_options
          options = []
          options << [:identity, @identity]                 if @identity
          options << [:"log-level", @log_level]             if @log_level
          options << :noout                                 if @noout
          options << [:root, @root]                         if @root
          options << [:runroot, @runroot]                   if @runroot
          options << [:runtime, @runtime]                   if @runtime
          options << [:"runtime-flag", @runtime_flag]       if @runtime_flag
          options << [:"storage-driver", @storage_driver]   if @storage_driver
          options << [:"storage-opt", @storage_opt]         if @storage_opt
          options << :syslog                                if @syslog
          options << [:tmpdir, @tmpdir]                     if @tmpdir
          options << [:"transient-store", @transient_store] if @transient_store
          options << [:volumepath, @volumepath]             if @volumepath
          options
        end
      end
    end
  end
end
