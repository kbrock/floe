# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Task < ManageIQ::Floe::Workflow::State
          attr_reader :credentials, :end, :heartbeat_seconds, :next, :parameters,
                      :result_selector, :resource, :timeout_seconds, :retry, :catch,
                      :input_path, :output_path, :result_path

          def initialize(workflow, name, payload)
            super

            @heartbeat_seconds = payload["HeartbeatSeconds"]
            @next              = payload["Next"]
            @resource          = payload["Resource"]
            @timeout_seconds   = payload["TimeoutSeconds"]
            @retry             = payload["Retry"].to_a.map { |retrier| Retrier.new(retrier) }
            @catch             = payload["Catch"].to_a.map { |catcher| Catcher.new(catcher) }
            @input_path        = Path.new(payload.fetch("InputPath", "$"))
            @output_path       = Path.new(payload.fetch("OutputPath", "$"))
            @result_path       = ReferencePath.new(payload.fetch("ResultPath", "$"))
            @parameters        = PayloadTemplate.new(payload["Parameters"])     if payload["Parameters"]
            @result_selector   = PayloadTemplate.new(payload["ResultSelector"]) if payload["ResultSelector"]
            @credentials       = PayloadTemplate.new(payload["Credentials"])    if payload["Credentials"]
          end

          def run!(*)
            super do |input|
              input = parameters.value(context, input) if parameters

              runner = ManageIQ::Floe::Workflow::Runner.for_resource(resource)
              _exit_status, results = runner.run!(resource, input, credentials&.value({}, workflow.credentials))

              output = input
              process_output!(output, results)
            rescue => err
              retrier = self.retry.detect { |r| (r.error_equals & [err.to_s, "States.ALL"]).any? }
              retry if retry!(retrier)

              catcher = self.catch.detect { |c| (c.error_equals & [err.to_s, "States.ALL"]).any? }
              raise if catcher.nil?

              [output, workflow.states_by_name[catcher.next]]
            end
          end

          private

          def retry!(retrier)
            return if retrier.nil?

            context["retrier"] ||= {"retry_count" => 0}
            context["retrier"]["retry_count"] += 1

            return if context["retrier"]["retry_count"] > retrier.max_attempts

            Kernel.sleep(retrier.sleep_duration(context["retrier"]["retry_count"]))
            true
          end

          def process_output!(output, results)
            return output if results.nil?
            return if output_path.nil?

            begin
              results = JSON.parse(results)
            rescue JSON::ParserError
              results = {"results" => results}
            end

            results = result_selector.value(context, results) if result_selector
            result_path.set(output, results)
          end
        end
      end
    end
  end
end
