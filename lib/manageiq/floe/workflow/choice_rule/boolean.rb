# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class Boolean < ManageIQ::Floe::Workflow::ChoiceRule
          def true?
            if payload.key?("Not")
              !ChoiceRule.true?(payload["Not"], context)
            elsif payload.key?("And")
              payload["And"].all? { |choice| ChoiceRule.true?(choice, context) }
            else
              payload["Or"].any? { |choice| ChoiceRule.true?(choice, context) }
            end
          end
        end
      end
    end
  end
end
