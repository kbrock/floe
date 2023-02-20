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

            @heartbeat_seconds = payload["HeartbeatSeconds"]
            @next              = payload["Next"]
            @resource          = payload["Resource"]
            @result_path       = payload.fetch("ResultPath", "$")
            @timeout_seconds   = payload["TimeoutSeconds"]
            @input_path        = Path.new(payload.fetch("InputPath", "$"), context)
            @output_path       = Path.new(payload.fetch("OutputPath", "$"), context)
            @parameters        = PayloadTemplate.new(payload["Parameters"])     if payload["Parameters"]
            @result_selector   = PayloadTemplate.new(payload["ResultSelector"]) if payload["ResultSelector"]
            @credentials       = PayloadTemplate.new(payload["Credentials"])    if payload["Credentials"]
          end

          def run!(input)
            super do
              input = input_path.value(input)
              input = parameters.value(context, input) if parameters

              runner = ManageIQ::Floe::Workflow::Runner.for_resource(resource)
              _exit_status, results = runner.run!(resource, input, credentials&.value(workflow.credentials))

              output = input
              process_output!(output, results)
            end
          end

          private

          def process_output!(output, results)
            return output if results.nil?
            return if output_path.nil?

            begin
              results = JSON.parse(results)
            rescue JSON::ParserError
              results = {"results" => results}
            end

            results = result_selector.value(context, results) if result_selector
            ReferencePath.set(result_path, output, results)
            output_path.value(output)
          end
        end
      end
    end
  end
end
