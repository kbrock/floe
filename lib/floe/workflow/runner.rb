# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      include Logging

      class << self
        attr_writer :docker_runner_klass

        def docker_runner_klass
          @docker_runner_klass ||= const_get(ENV.fetch("DOCKER_RUNNER", "docker").capitalize)
        end

        def for_resource(resource)
          raise ArgumentError, "resource cannot be nil" if resource.nil?

          scheme = resource.split("://").first
          case scheme
          when "docker"
            docker_runner_klass.new
          else
            raise "Invalid resource scheme [#{scheme}]"
          end
        end
      end

      def run!(image, env = {}, secrets = {})
        raise NotImplementedError, "Must be implemented in a subclass"
      end
    end
  end
end
