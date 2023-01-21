# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        require "jsonpath"

        attr_reader :context, :next, :payload, :variable

        def initialize(payload, context)
          @context = context.to_json
          @payload = payload

          @next     = payload["Next"]
          @variable = payload["Variable"]
        end
      end
    end
  end
end
