# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Choice < Floe::Workflow::State
        attr_reader :choices, :default, :input_path, :output_path

        def initialize(workflow, name, payload)
          super

          @choices = payload["Choices"].map { |choice| ChoiceRule.build(choice) }
          @default = payload["Default"]

          @input_path  = Path.new(payload.fetch("InputPath", "$"))
          @output_path = Path.new(payload.fetch("OutputPath", "$"))
        end

        def start(input)
          super
          input      = input_path.value(context, input)
          next_state = choices.detect { |choice| choice.true?(context, input) }&.next || default
          output     = output_path.value(context, input)

          context.next_state = next_state
          context.output     = output
        end

        def running?
          false
        end

        def end?
          false
        end
      end
    end
  end
end
