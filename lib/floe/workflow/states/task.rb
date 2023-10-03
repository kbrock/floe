# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Task < Floe::Workflow::State
        attr_reader :credentials, :end, :heartbeat_seconds, :next, :parameters,
                    :result_selector, :resource, :timeout_seconds, :retry, :catch,
                    :input_path, :output_path, :result_path

        def initialize(workflow, name, payload)
          super

          @heartbeat_seconds = payload["HeartbeatSeconds"]
          @next              = payload["Next"]
          @end               = !!payload["End"]
          @resource          = payload["Resource"]
          @runner            = Floe::Workflow::Runner.for_resource(@resource)
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

        def start(input)
          super

          input          = process_input(input)
          runner_context = runner.run_async!(resource, input, credentials&.value({}, workflow.credentials))

          context.state["RunnerContext"] = runner_context
        end

        def status
          @end ? "success" : "running"
        end

        def finish
          output = runner.output(context.state["RunnerContext"])

          if success?
            output = parse_output(output)
            context.state["Output"] = process_output!(output)
            context.next_state      = next_state
          else
            error = parse_error(output)
            retry_state!(error) || catch_error!(error) || fail_workflow!(error)
          end

          super
        ensure
          runner.cleanup(context.state["RunnerContext"])
        end

        def running?
          return true if waiting?

          runner.status!(context.state["RunnerContext"])
          runner.running?(context.state["RunnerContext"])
        end

        def end?
          @end
        end

        private

        attr_reader :runner

        def success?
          runner.success?(context.state["RunnerContext"])
        end

        def find_retrier(error)
          self.retry.detect { |r| (r.error_equals & [error, "States.ALL"]).any? }
        end

        def find_catcher(error)
          self.catch.detect { |c| (c.error_equals & [error, "States.ALL"]).any? }
        end

        def retry_state!(error)
          retrier = find_retrier(error["Error"]) if error
          return if retrier.nil?

          # If a different retrier is hit reset the context
          if !context["State"].key?("RetryCount") || context["State"]["Retrier"] != retrier.error_equals
            context["State"]["RetryCount"] = 0
            context["State"]["Retrier"]    = retrier.error_equals
          end

          context["State"]["RetryCount"] += 1

          return if context["State"]["RetryCount"] > retrier.max_attempts

          wait(:seconds => retrier.sleep_duration(context["State"]["RetryCount"]))
          context.next_state = context.state_name
          true
        end

        def catch_error!(error)
          catcher = find_catcher(error["Error"]) if error
          return if catcher.nil?

          context.next_state = catcher.next
          context.output     = catcher.result_path.set(context.input, error)
          true
        end

        def fail_workflow!(error)
          context.next_state     = nil
          context.output         = {"Error" => error["Error"], "Cause" => error["Cause"]}.compact
          context.state["Error"] = context.output["Error"]
        end

        def process_input(input)
          input = input_path.value(context, input)
          input = parameters.value(context, input) if parameters
          input
        end

        def parse_error(output)
          return if output.nil?

          JSON.parse(output)
        rescue JSON::ParserError
          {"Error" => output}
        end

        def parse_output(output)
          return if output.nil?

          JSON.parse(output.split("\n").last)
        rescue JSON::ParserError
          nil
        end

        def process_output!(results)
          output = context.input.dup
          return output if results.nil?
          return if output_path.nil?

          results = result_selector.value(context, results) if result_selector
          output  = result_path.set(output, results)
          output_path.value(context, output)
        end

        def next_state
          end? ? nil : @next
        end
      end
    end
  end
end
