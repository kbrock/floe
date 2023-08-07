# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class Or < Floe::Workflow::ChoiceRule
        def true?(context, input)
          children.any? { |choice| choice.true?(context, input) }
        end
      end
    end
  end
end
