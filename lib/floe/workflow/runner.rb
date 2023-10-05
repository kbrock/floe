# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      include Logging

      TYPES         = %w[docker podman kubernetes].freeze
      OUTPUT_MARKER = "__FLOE_OUTPUT__\n"

      def initialize(_options = {})
      end

      class << self
        attr_writer :docker_runner

        def docker_runner
          @docker_runner ||= Floe::Workflow::Runner::Docker.new
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

      def run_async!(_image, _env = {}, _secrets = {})
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def running?(_ref)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def success?(_ref)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def output(_ref)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def cleanup(_ref, _secret)
        raise NotImplementedError, "Must be implemented in a subclass"
      end
    end
  end
end
