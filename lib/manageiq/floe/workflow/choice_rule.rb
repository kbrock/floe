# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class << self
          def true?(payload, context, input)
            build(payload).true?(context, input)
          end

          def build(payload)
            data_expression = (payload.keys & %w[And Not Or]).empty?
            if data_expression
              ManageIQ::Floe::Workflow::ChoiceRule::Data.new(payload)
            else
              ManageIQ::Floe::Workflow::ChoiceRule::Boolean.new(payload)
            end
          end
        end

        attr_reader :next, :payload, :variable

        def initialize(payload)
          @payload = payload

          @next     = payload["Next"]
          @variable = payload["Variable"]
        end

        def true?(*)
          raise NotImplementedError, "Must be implemented in a subclass"
        end

        private

        def variable_value(context, input)
          @variable_value ||= Path.value(variable, context, input)
        end
      end
    end
  end
end
