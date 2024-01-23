# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      include Logging

      OUTPUT_MARKER = "__FLOE_OUTPUT__\n"

      def initialize(_options = {})
      end

      @runners = {}
      class << self
        # deprecated -- use Floe.set_runner instead
        def docker_runner=(value)
          set_runner("docker", value)
        end

        # see Floe.set_runner
        def set_runner(scheme, name_or_instance, options = {})
          @runners[scheme] =
            case name_or_instance
            when "docker", nil
              Floe::Workflow::Runner::Docker.new(options)
            when "podman"
              Floe::Workflow::Runner::Podman.new(options)
            when "kubernetes"
              Floe::Workflow::Runner::Kubernetes.new(options)
            when Floe::Workflow::Runner
              name_or_instance
            else
              raise ArgumentError, "docker runner must be one of: docker, podman, kubernetes"
            end
        end

        def for_resource(resource)
          raise ArgumentError, "resource cannot be nil" if resource.nil?

          # if no runners are set, default docker:// to docker
          set_runner("docker", "docker") if @runners.empty?
          scheme = resource.split("://").first
          @runners[scheme] || raise(ArgumentError, "Invalid resource scheme [#{scheme}]")
        end
      end

      def run!(resource, env = {}, secrets = {})
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      # @return [Hash] runner_context
      def run_async!(_image, _env = {}, _secrets = {})
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def running?(_runner_context)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def success?(_runner_context)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def output(_runner_context)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def cleanup(_runner_context)
        raise NotImplementedError, "Must be implemented in a subclass"
      end
    end
  end
end
