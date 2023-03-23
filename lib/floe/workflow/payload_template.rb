# frozen_string_literal: true

module Floe
  class Workflow
    class PayloadTemplate
      def initialize(payload)
        @payload = payload
      end

      def value(context, inputs = {})
        interpolate_value_nested(payload, context, inputs)
      end

      private

      attr_reader :payload

      def interpolate_value_nested(value, context, inputs)
        case value
        when Array
          value.map { |val| interpolate_value_nested(val, context, inputs) }
        when Hash
          value.to_h do |key, val|
            val = interpolate_value_nested(val, context, inputs)
            key = key.gsub(/\.\$$/, "") if key.end_with?(".$")

            [key, val]
          end
        when String
          value.start_with?("$") ? Path.value(value, context, inputs) : value
        else
          value
        end
      end
    end
  end
end
