# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class And < Floe::Workflow::ChoiceRule
        def true?(context, input)
          children.all? { |choice| choice.true?(context, input) }
        end
      end
    end
  end
end
