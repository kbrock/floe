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
            @result_path = JsonPath.new(payload["ResultPath"]) if payload.key?("ResultPath")
          end
        end
      end
    end
  end
end
