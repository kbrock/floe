# frozen_string_literal: true

module Floe
  class Workflow
    class State
      include Logging

      class << self
        def build!(workflow, name, payload)
          state_type = payload["Type"]

          begin
            klass = Floe::Workflow::States.const_get(state_type)
          rescue NameError
            raise Floe::InvalidWorkflowError, "Invalid state type: [#{state_type}]"
          end

          klass.new(workflow, name, payload)
        end
      end

      attr_reader :workflow, :comment, :name, :type, :payload

      def initialize(workflow, name, payload)
        @workflow = workflow
        @name     = name
        @payload  = payload
        @type     = payload["Type"]
        @comment  = payload["Comment"]
      end

      def run!(input)
        start(input)
        sleep(1) while running?
        finish
        [context.next_state, context.output]
      end

      def start(_input)
        raise NotImpelmentedError
      end

      def finish
        context.state["FinishedTime"] ||= Time.now.utc.iso8601
      end

      def context
        workflow.context
      end

      def started?
        context.state.key?("EnteredTime")
      end

      def ready?
        !started? || !running?
      end

      def finished?
        context.state.key?("FinishedTime")
      end
    end
  end
end
