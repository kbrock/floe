# frozen_string_literal: true

module Floe
  class Workflow
    class Runner
      include Logging

      TYPES = %w[docker podman kubernetes].freeze

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

      def run!(image, env = {}, secrets = {})
        raise NotImplementedError, "Must be implemented in a subclass"
      end
    end
  end
end
