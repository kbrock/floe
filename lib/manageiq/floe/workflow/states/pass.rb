# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Pass < ManageIQ::Floe::Workflow::State
          attr_reader :end, :next, :result, :result_path

          def initialize(workflow, name, payload)
            require "more_core_extensions/core_ext/hash/nested"
            require "more_core_extensions/core_ext/array/nested"
            super

            @next        = payload["Next"]
            @result      = payload["Result"]
            @result_path = JsonPath.new(payload["ResultPath"]) if payload.key?("ResultPath")
          end

          def run!
            logger.info("Running state: [#{name}]")

            if result
              path = result_path.path[1..]
                                .map { |v| v.match(/\[(?<name>.+)\]/)["name"] }
                                .map { |v| v[0] == "'" ? v.gsub("'", "") : v.to_i }

              workflow.context.store_path(path, result)
            end

            next_state = workflow.states_by_name[@next] unless end?

            [next_state, result]
          end
        end
      end
    end
  end
end
