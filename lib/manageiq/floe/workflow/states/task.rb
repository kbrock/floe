# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Task < ManageIQ::Floe::Workflow::State
          attr_reader :credentials, :end, :heartbeat_seconds, :next, :parameters,
                      :result_selector, :resource, :timeout_seconds

          def initialize(workflow, name, payload)
            super

            @credentials       = payload["Credentials"]
            @heartbeat_seconds = payload["HeartbeatSeconds"]
            @next              = payload["Next"]
            @parameters        = payload["Parameters"]
            @result_selector   = payload["ResultSelector"]
            @resource          = payload["Resource"]
            @timeout_seconds   = payload["TimeoutSeconds"]
          end

          def run!
            logger.info("Running state: [#{name}]")

            runner = ManageIQ::Floe::Workflow::Runner.for_resource(resource)
            _exit_status, outputs = runner.run!(resource, parameters, credentials)

            next_state = workflow.states_by_name[@next] unless end?

            [next_state, outputs]
          end
        end
      end
    end
  end
end
