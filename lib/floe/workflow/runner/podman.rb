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

          params  = ["run", :rm]
          params += [[:net, "host"]] if @network == "host"
          params += env.map { |k, v| [:e, "#{k}=#{v}"] } if env

          if secrets && !secrets.empty?
            secret_guid = SecureRandom.uuid
            podman!("secret", "create", secret_guid, "-", :in_data => secrets.to_json)

            params << [:e, "_CREDENTIALS=/run/secrets/#{secret_guid}"]
            params << [:secret, secret_guid]
          end

          params << image

          logger.debug("Running podman: #{AwesomeSpawn.build_command_line("podman", params)}")
          result = podman!(*params)

          [result.exit_status, result.output]
        ensure
          AwesomeSpawn.run("podman", :params => ["secret", "rm", secret_guid]) if secret_guid
        end

        private

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
