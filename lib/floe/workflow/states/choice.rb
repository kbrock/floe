# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Choice < Floe::Workflow::State
        attr_reader :choices, :default, :input_path, :output_path

        def initialize(workflow, name, payload)
          super

          validate_state!

          @choices = payload["Choices"].map { |choice| ChoiceRule.build(choice) }
          @default = payload["Default"]

          @input_path  = Path.new(payload.fetch("InputPath", "$"))
          @output_path = Path.new(payload.fetch("OutputPath", "$"))
        end

        def finish
          output     = output_path.value(context, context.input)
          next_state = choices.detect { |choice| choice.true?(context, output) }&.next || default

          context.next_state = next_state
          context.output     = output
          super
        end

        def running?
          false
        end

        def end?
          false
        end

        private

        def validate_state!
          validate_state_choices!
          validate_state_default!
        end

        def validate_state_choices!
          raise Floe::InvalidWorkflowError, "Choice state must have \"Choices\"" unless payload.key?("Choices")
          raise Floe::InvalidWorkflowError, "\"Choices\" must be a non-empty array" unless payload["Choices"].kind_of?(Array) && !payload["Choices"].empty?
        end

        def validate_state_default!
          raise Floe::InvalidWorkflowError, "\"Default\" not in \"States\"" unless workflow.payload["States"].include?(payload["Default"])
        end
      end
    end
  end
end
