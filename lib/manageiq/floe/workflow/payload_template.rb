# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class PayloadTemplate
        def initialize(payload, context)
          @payload = payload
          @context = context
        end

        def value(inputs = {})
          interpolate_value_nested(payload, inputs)
        end

        private

        attr_reader :payload, :context

        def interpolate_value_nested(value, inputs)
          case value
          when Array
            value.map { |val| interpolate_value_nested(val, inputs) }
          when Hash
            value.to_h do |key, val|
              val = interpolate_value_nested(val, inputs)
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
end
