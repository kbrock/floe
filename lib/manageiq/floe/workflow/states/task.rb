# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Task < ManageIQ::Floe::Workflow::State
          attr_reader :credentials, :end, :heartbeat_seconds, :next, :parameters,
                      :result_selector, :resource, :timeout_seconds,
                      :input_path, :output_path, :result_path

          def initialize(workflow, name, payload)
            super

            @credentials       = payload["Credentials"]
            @heartbeat_seconds = payload["HeartbeatSeconds"]
            @next              = payload["Next"]
            @resource          = payload["Resource"]
            @result_path       = payload.fetch("ResultPath", "$")
            @timeout_seconds   = payload["TimeoutSeconds"]

            @input_path  = Path.new(payload.fetch("InputPath", "$"), context)
            @output_path = Path.new(payload.fetch("OutputPath", "$"), context)

            @parameters      = PayloadTemplate.new(payload["Parameters"], context) if payload["Parameters"]
            @result_selector = PayloadTemplate.new(payload["ResultSelector"], context) if payload["ResultSelector"]
          end

          def run!
            logger.info("Running state: [#{name}]")

            input = input_path.value(context)
            input = parameters.value(input) if parameters

            runner = ManageIQ::Floe::Workflow::Runner.for_resource(resource)
            _exit_status, results = runner.run!(resource, input, credentials)

            output = input
            if results
              begin
                results = JSON.parse(results)
              rescue JSON::ParserError
                results = {"results" => results}
              end

              results = result_selector.value(results)        if result_selector
              ReferencePath.set(result_path, output, results)
            end

            next_state = workflow.states_by_name[@next] unless end?

            logger.info("next state: [#{next_state&.name}] output: [#{output}]")
            [next_state, output]
          end
        end
      end
    end
  end
end
