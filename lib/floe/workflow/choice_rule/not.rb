# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class Not < Floe::Workflow::ChoiceRule
        def true?(context, input)
          choice = children.first
          !choice.true?(context, input)
        end
      end
    end
  end
end
