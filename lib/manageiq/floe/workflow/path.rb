# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class Path
        class << self
          def value(payload, context, input = {})
            new(payload, context).value(input)
          end
        end

        def initialize(payload, context)
          @payload = payload
          @context = context
        end

        def value(input = {})
          obj, path =
            if payload.start_with?("$$")
              [context, payload[1..]]
            else
              [input, payload]
            end

          results = JsonPath.on(obj, path)

          results.count < 2 ? results.first : results
        end

        private

        attr_reader :payload, :context
      end
    end
  end
end
