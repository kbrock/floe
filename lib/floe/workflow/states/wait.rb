# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Wait < Floe::Workflow::State
        attr_reader :end, :next, :seconds, :input_path, :output_path

        def initialize(workflow, name, payload)
          super

          @next    = payload["Next"]
          @end     = !!payload["End"]
          @seconds = payload["Seconds"].to_i

          @input_path  = Path.new(payload.fetch("InputPath", "$"))
          @output_path = Path.new(payload.fetch("OutputPath", "$"))
        end

        def run_async!(input)
          input = input_path.value(context, input)

          context.output     = output_path.value(context, input)
          context.next_state = end? ? nil : @next
        end

        def running?
          now = Time.now.utc
          if now > (context.state["EnteredTime"] + @seconds)
            context.state["FinishedTime"] = now
            false
          else
            true
          end
        end

        def end?
          @end
        end
      end
    end
  end
end
