# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Wait < ManageIQ::Floe::Workflow::State
          attr_reader :end, :next, :seconds, :input_path, :output_path

          def initialize(workflow, name, payload)
            super

            @next    = payload["Next"]
            @seconds = payload["Seconds"].to_i

            @input_path  = Path.new(payload.fetch("InputPath", "$"), context)
            @output_path = Path.new(payload.fetch("OutputPath", "$"), context)
          end

          def run!(input)
            logger.info("Running state: [#{name}] with input [#{input}]")
            sleep(seconds)

            super
          end
        end
      end
    end
  end
end
