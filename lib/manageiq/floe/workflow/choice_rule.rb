# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class << self
          def true?(payload, context)
            build(payload, context).true?
          end

          def build(payload, context)
            data_expression = (payload.keys & %w[And Not Or]).empty?
            if data_expression
              ManageIQ::Floe::Workflow::ChoiceRule::Data.new(payload, context)
            else
              ManageIQ::Floe::Workflow::ChoiceRule::Boolean.new(payload, context)
            end
          end
        end

        attr_reader :context, :next, :payload, :variable

        def initialize(payload, context)
          @context = context
          @payload = payload

          @next     = payload["Next"]
          @variable = payload["Variable"]
        end

        def true?
          raise NotImplementedError, "Must be implemented in a subclass"
        end

        private

        def variable_value
          @variable_value ||= JsonPath.on(context, variable).first
        end
      end
    end
  end
end
