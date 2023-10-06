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

      def run!(_input = nil)
        run_wait until run_nonblock! == 0
      end

      def run_wait(timeout: 5)
        start = Time.now.utc

        loop do
          return 0             if ready?
          return Errno::EAGAIN if timeout.zero? || Time.now.utc - start > timeout

          sleep(1)
        end
      end

      def run_nonblock!
        start(context.input) unless started?
        return Errno::EAGAIN unless ready?

        finish
      end

      def start(_input)
        start_time = Time.now.utc.iso8601

        context.execution["StartTime"] ||= start_time
        context.state["Guid"]            = SecureRandom.uuid
        context.state["EnteredTime"]     = start_time

        logger.info("Running state: [#{context.state_name}] with input [#{context.input}]...")
      end

      def finish
        finished_time     = Time.now.utc
        finished_time_iso = finished_time.iso8601
        entered_time      = Time.parse(context.state["EnteredTime"])

        context.state["FinishedTime"] ||= finished_time_iso
        context.state["Duration"]       = finished_time - entered_time
        context.execution["EndTime"]    = finished_time_iso if context.next_state.nil?

        logger.info("Running state: [#{context.state_name}] with input [#{context.input}]...Complete - next state: [#{context.next_state}] output: [#{context.output}]")

        context.state_history << context.state

        0
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

      private

      def wait(seconds: nil, time: nil)
        context.state["WaitUntil"] =
          if seconds
            (Time.parse(context.state["EnteredTime"]) + seconds).iso8601
          elsif time.kind_of?(String)
            time
          else
            time.iso8601
          end
      end

      def waiting?
        context.state["WaitUntil"] && Time.now.utc <= Time.parse(context.state["WaitUntil"])
      end
    end
  end
end
