# frozen_string_literal: true

module Floe
  class Runner
    include Logging

    OUTPUT_MARKER = "__FLOE_OUTPUT__\n"

    def initialize(_options = {})
    end

    @runners = {}
    class << self
      def register_scheme(scheme, klass_or_proc)
        @runners[scheme] = klass_or_proc
      end

      private def resolve_scheme(scheme)
        runner = @runners[scheme]
        runner = @runners[scheme] = @runners[scheme].call if runner.is_a?(Proc)
        runner
      end

      def for_resource(resource)
        raise ArgumentError, "resource cannot be nil" if resource.nil?

        scheme = resource.split("://").first
        resolve_scheme(scheme) || raise(ArgumentError, "Invalid resource scheme [#{scheme}]")
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

    def wait(timeout: nil, events: %i[create update delete])
      raise NotImplementedError, "Must be implemented in a subclass"
    end
  end
end
