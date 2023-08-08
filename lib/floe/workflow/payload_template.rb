# frozen_string_literal: true

module Floe
  class Workflow
    class PayloadTemplate
      def initialize(payload)
        @payload          = payload
        @payload_template = parse_payload(payload)
      end

      def value(context, inputs = {})
        interpolate_value(payload_template, context, inputs)
      end

      private

      attr_reader :payload, :payload_template

      def parse_payload(value)
        case value
        when Array
          value.map { |val| parse_payload(val) }
        when Hash
          value.to_h do |key, val|
            if key.end_with?(".$")
              if value.key?(key.chomp(".$"))
                raise Floe::InvalidWorkflowError, "both #{key} and #{key.chomp(".$")} present"
              end

              [key, parse_payload(val)]
            else
              [key, val]
            end
          end
        when String
          if value.start_with?("$")
            Path.new(value)
          else
            value
          end
        else
          value
        end
      end

      def interpolate_value(value, context, inputs)
        case value
        when Array
          value.map { |val| interpolate_value(val, context, inputs) }
        when Hash
          value.to_h do |key, val|
            if key.end_with?(".$")
              [key.chomp(".$"), interpolate_value(val, context, inputs)]
            else
              [key, val]
            end
          end
        when Path
          value.value(context, inputs)
        else
          value
        end
      end
    end
  end
end
