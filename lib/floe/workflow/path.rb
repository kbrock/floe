# frozen_string_literal: true

module Floe
  class Workflow
    class Path
      class << self
        def value(payload, context, input = {})
          new(payload).value(context, input)
        end
      end

      def initialize(payload)
        @payload = payload
      end

      def value(context, input = {})
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

      attr_reader :payload
    end
  end
end
