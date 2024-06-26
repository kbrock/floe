# frozen_string_literal: true

module Floe
  class Workflow
    class State
      include Logging

      class << self
        def build!(workflow, name, payload)
          state_type = payload["Type"]
          raise Floe::InvalidWorkflowError, "Missing \"Type\" field in state [#{name}]" if payload["Type"].nil?

          begin
            klass = Floe::Workflow::States.const_get(state_type)
          rescue NameError
            raise Floe::InvalidWorkflowError, "Invalid state type: [#{state_type}]"
          end

          klass.new(workflow, name, payload)
        end
      end

      attr_reader :comment, :name, :type, :payload

      def initialize(workflow, name, payload)
        @name     = name
        @payload  = payload
        @type     = payload["Type"]
        @comment  = payload["Comment"]

        raise Floe::InvalidWorkflowError, "Missing \"Type\" field in state [#{name}]" if payload["Type"].nil?
        raise Floe::InvalidWorkflowError, "State name [#{name[..79]}...] must be less than or equal to 80 characters" if name.length > 80
      end

      def wait(context, timeout: nil)
        start = Time.now.utc

        loop do
          return 0             if ready?(context)
          return Errno::EAGAIN if timeout && (timeout.zero? || Time.now.utc - start > timeout)

          sleep(1)
        end
      end

      # @return for incomplete Errno::EAGAIN, for completed 0
      def run_nonblock!(context)
        start(context) unless context.state_started?
        return Errno::EAGAIN unless ready?(context)

        finish(context)
      end

      def start(context)
        context.state["EnteredTime"] = Time.now.utc.iso8601

        logger.info("Running state: [#{long_name}] with input [#{context.json_input}]...")
      end

      def finish(context)
        finished_time     = Time.now.utc
        entered_time      = Time.parse(context.state["EnteredTime"])

        context.state["FinishedTime"] ||= finished_time.iso8601
        context.state["Duration"]       = finished_time - entered_time

        level = context.failed? ? :error : :info
        logger.public_send(level, "Running state: [#{long_name}] with input [#{context.json_input}]...Complete #{context.next_state ? "- next state [#{context.next_state}]" : "workflow -"} output: [#{context.json_output}]")

        0
      end

      def ready?(context)
        !context.state_started? || !running?(context)
      end

      def running?(context)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      def waiting?(context)
        context.state["WaitUntil"] && Time.now.utc <= Time.parse(context.state["WaitUntil"])
      end

      def wait_until(context)
        context.state["WaitUntil"] && Time.parse(context.state["WaitUntil"])
      end

      def long_name
        "#{@type}:#{name}"
      end

      private

      def wait_until!(context, seconds: nil, time: nil)
        context.state["WaitUntil"] =
          if seconds
            (Time.parse(context.state["EnteredTime"]) + seconds).iso8601
          elsif time.kind_of?(String)
            time
          else
            time.iso8601
          end
      end
    end
  end
end
