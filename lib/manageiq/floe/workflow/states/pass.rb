# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Pass < ManageIQ::Floe::Workflow::State
          attr_reader :end, :next, :result, :parameters, :input_path, :output_path, :result_path

          def initialize(workflow, name, payload)
            super

            @next        = payload["Next"]
            @result      = payload["Result"]

            @parameters  = PayloadTemplate.new(payload["Parameters"], context) if payload["Parameters"]
            @input_path  = Path.new(payload.fetch("InputPath", "$"), context)
            @output_path = Path.new(payload.fetch("OutputPath", "$"), context)
            @result_path = payload.fetch("ResultPath", "$")
          end

          def run!(input)
            super do
              output = input
              ReferencePath.set(result_path, output, result) if result && result_path
              output
            end
          end
        end
      end
    end
  end
end
