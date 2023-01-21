# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class Boolean < ManageIQ::Floe::Workflow::ChoiceRule
          def true?
            if payload.key?("Not")
              !ChoiceRule.build(payload["Not"], context).true?
            elsif payload.key?("And")
              payload["And"].all? { |choice| ChoiceRule.build(choice, context).true? }
            else
              payload["Or"].any? { |choice| ChoiceRule.build(choice, context).true? }
            end
          end
        end
      end
    end
  end
end
