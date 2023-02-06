# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class << self
          def true?(payload, context, input)
            build(payload, context, input).true?
          end

          def build(payload, context, input)
            data_expression = (payload.keys & %w[And Not Or]).empty?
            if data_expression
              ManageIQ::Floe::Workflow::ChoiceRule::Data.new(payload, context, input)
            else
              ManageIQ::Floe::Workflow::ChoiceRule::Boolean.new(payload, context, input)
            end
          end
        end

        attr_reader :context, :input, :next, :payload, :variable

        def initialize(payload, context, input)
          @context = context
          @input   = input
          @payload = payload

          @next     = payload["Next"]
          @variable = payload["Variable"]
        end

        def true?
          raise NotImplementedError, "Must be implemented in a subclass"
        end

        private

        def variable_value
          @variable_value ||= Path.value(variable, context, input)
        end
      end
    end
  end
end
