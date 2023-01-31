# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Pass < ManageIQ::Floe::Workflow::State
          attr_reader :end, :next, :result, :result_path

          def initialize(workflow, name, payload)
            super

            @next        = payload["Next"]
            @result      = payload["Result"]
            @result_path = ReferencePath.new(payload["ResultPath"], context) if payload.key?("ResultPath")
          end

          def run!
            logger.info("Running state: [#{name}]")

            result_path.set(result) if result && result_path

            next_state = workflow.states_by_name[@next] unless end?

            [next_state, result]
          end
        end
      end
    end
  end
end
