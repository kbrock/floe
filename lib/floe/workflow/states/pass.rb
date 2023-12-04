# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Pass < Floe::Workflow::State
        include NonTerminalMixin

        attr_reader :end, :next, :result, :parameters, :input_path, :output_path, :result_path

        def initialize(workflow, name, payload)
          super

          @next        = payload["Next"]
          @end         = !!payload["End"]
          @result      = payload["Result"]

          @parameters  = PayloadTemplate.new(payload["Parameters"]) if payload["Parameters"]
          @input_path  = Path.new(payload.fetch("InputPath", "$"))
          @output_path = Path.new(payload.fetch("OutputPath", "$"))
          @result_path = ReferencePath.new(payload.fetch("ResultPath", "$"))

          validate_state!
        end

        def start(input)
          super
          output = input_path.value(context, input)
          if result && result_path
            if result_path.payload.start_with?("$.Credentials")
              credentials = result_path.set(workflow.credentials, result)["Credentials"]
              workflow.credentials.merge!(credentials)
            else
              output = result_path.set(output, result)
            end
          end
          output = output_path.value(context, output)

          context.next_state = end? ? nil : @next
          context.output     = output
        end

        def running?
          false
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
