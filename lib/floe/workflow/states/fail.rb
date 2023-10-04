# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Fail < Floe::Workflow::State
        attr_reader :cause, :error

        def initialize(workflow, name, payload)
          super

          @cause      = payload["Cause"]
          @error      = payload["Error"]
          @cause_path = Path.new(payload["CausePath"]) if payload["CausePath"]
          @error_path = Path.new(payload["ErrorPath"]) if payload["ErrorPath"]
        end

        def start(input)
          super
          context.next_state = nil
          # TODO: support intrinsic functions here
          # see https://docs.aws.amazon.com/step-functions/latest/dg/amazon-states-language-fail-state.html
          #     https://docs.aws.amazon.com/step-functions/latest/dg/amazon-states-language-intrinsic-functions.html#asl-intrsc-func-generic
          context.output     = {
            "Error" => value_or_path(context, input, error, :path => @error_path),
            "Cause" => value_or_path(context, input, cause, :path => @cause_path)
          }.compact
          context.state["Error"] = context.output["Error"]
          context.state["Cause"] = context.output["Cause"]
        end

        def running?
          false
        end

        def end?
          true
        end
      end
    end
  end
end
