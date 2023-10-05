# frozen_string_literal: true

require 'time'

module Floe
  class Workflow
    module States
      class Wait < Floe::Workflow::State
        attr_reader :end, :next, :seconds, :input_path, :output_path

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
        end

        def start(input)
          super
          input = input_path.value(context, input)

          context.output     = output_path.value(context, input)
          context.next_state = end? ? nil : @next
          wait(
            :seconds => value_or_path(context, input, @seconds, :path => @seconds_path, &:to_i),
            :time    => value_or_path(context, input, @timestamp, :path => @timestamp_path)
          )
        end

        def running?
          waiting?
        end

        def end?
          @end
        end
      end
    end
  end
end
