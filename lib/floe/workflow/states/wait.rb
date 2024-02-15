# frozen_string_literal: true

require 'time'

module Floe
  class Workflow
    module States
      class Wait < Floe::Workflow::State
        include NonTerminalMixin

        attr_reader :end, :input_path, :next, :seconds, :seconds_path, :timestamp, :timestamp_path, :output_path

        def initialize(workflow, name, payload)
          super

          @next           = payload["Next"]
          @end            = !!payload["End"]
          @seconds        = payload["Seconds"]&.to_i
          @timestamp      = payload["Timestamp"]
          @timestamp_path = Path.new(payload["TimestampPath"]) if payload.key?("TimestampPath")
          @seconds_path   = Path.new(payload["SecondsPath"]) if payload.key?("SecondsPath")

          @input_path  = Path.new(payload.fetch("InputPath", "$"))
          @output_path = Path.new(payload.fetch("OutputPath", "$"))

          validate_state!
        end

        def start(input)
          super

          input          = input_path.value(context, input)
          context.output = output_path.value(context, input)

          wait_until!(
            :seconds => seconds_path ? seconds_path.value(context, input).to_i : seconds,
            :time    => timestamp_path ? timestamp_path.value(context, input) : timestamp
          )
        end

        def running?
          waiting?
        end

        def end?
          @end
        end

        private

        def validate_state!
          validate_state_next!
        end
      end
    end
  end
end
