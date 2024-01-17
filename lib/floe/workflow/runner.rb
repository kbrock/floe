# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      include Logging

      OUTPUT_MARKER = "__FLOE_OUTPUT__\n"

      def initialize(_options = {})
      end

      class << self
        # deprecated -- use Floe.set_runner instead
        def docker_runner=(value)
          set_runner(value)
        end

        # see Floe.set_runner
        def set_runner(name_or_instance, options = {})
          @docker_runner =
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

        def docker_runner
          @docker_runner || set_runner("docker")
        end

        def for_resource(resource)
          raise ArgumentError, "resource cannot be nil" if resource.nil?

          scheme = resource.split("://").first
          case scheme
          when "docker"
            docker_runner
          else
            raise "Invalid resource scheme [#{scheme}]"
          end
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
