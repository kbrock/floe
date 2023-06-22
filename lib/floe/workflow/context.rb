# frozen_string_literal: true

module Floe
  class Workflow
    class Context
      def initialize(context = nil, input: {})
        context = JSON.parse(context) if context&.kind_of?(String)

        @context = context || {
          "Execution"    => {
            "Input" => input
          },
          "State"        => {},
          "States"       => [],
          "StateMachine" => {
          },
          "Task"         => {
          }
        }
      end

      def execution
        @context["Execution"]
      end

      def state
        @context["State"]
      end

      def states
        @context["States"]
      end

      def state_machine
        @context["StateMachine"]
      end

      def task
        @context["Task"]
      end

      def [](key)
        @context[key]
      end

      def []=(key, val)
        @context[key] = val
      end

      def dig(*args)
        @context.dig(*args)
      end

      def to_h
        @context
      end
    end
  end
end
