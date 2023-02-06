# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class Data < ManageIQ::Floe::Workflow::ChoiceRule
          def true?
            validate!

            case compare_key
            when "IsNull"; is_null?
            when "IsPresent"; is_present?
            when "IsNumeric"; is_numeric?
            when "IsString"; is_string?
            when "IsBoolean"; is_boolean?
            when "IsTimestamp"; is_timestamp?
            when "StringEquals", "StringEqualsPath",
                 "NumericEquals", "NumericEqualsPath",
                 "BooleanEquals", "BooleanEqualsPath",
                 "TimestampEquals", "TimestampEqualsPath"
              variable_value == compare_value
            when "StringLessThan", "StringLessThanPath",
                 "NumericLessThan", "NumericLessThanPath",
                 "TimestampLessThan", "TimestampLessThanPath"
              variable_value < compare_value
            when "StringGreaterThan", "StringGreaterThanPath",
                 "NumericGreaterThan", "NumericGreaterThanPath",
                 "TimestampGreaterThan", "TimestampGreaterThanPath"
              variable_value > compare_value
            when "StringLessThanEquals", "StringLessThanEqualsPath",
                 "NumericLessThanEquals", "NumericLessThanEqualsPath",
                 "TimestampLessThanEquals", "TimestampLessThanEqualsPath"
              variable_value <= compare_value
            when "StringGreaterThanEquals", "StringGreaterThanEqualsPath",
                 "NumericGreaterThanEquals", "NumericGreaterThanEqualsPath",
                 "TimestampGreaterThanEquals", "TimestampGreaterThanEqualsPath"
              variable_value >= compare_value
            when "StringMatches"
              variable_value.match?(Regexp.escape(compare_value).gsub('\*','.*?'))
            else
              raise ManageIQ::Floe::InvalidWorkflowError, "Invalid choice [#{compare_key}]"
            end
          end

          private

          def validate!
            raise RuntimeError, "No such variable [#{variable}]" if variable_value.nil? && !%w[IsNull IsPresent].include?(compare_key)
          end

          def is_null?
            variable_value.nil?
          end

          def is_present?
            !variable_value.nil?
          end

          def is_numeric?
            variable_value.kind_of?(Integer) || variable_value.kind_of?(Float)
          end

          def is_string?
            variable_value.kind_of?(String)
          end

          def is_boolean?
            [true, false].include?(variable_value)
          end

          def is_timestamp?
            require "date"

            DateTime.rfc3339(variable_value)
            true
          rescue TypeError, Date::Error
            false
          end

          def compare_key
            @compare_key ||= payload.keys.detect { |key| key.match?(/^(IsNull|IsPresent|IsNumeric|IsString|IsBoolean|IsTimestamp|String|Numeric|Boolean|Timestamp)/) }
          end

          def compare_value
            @compare_value ||= compare_key.end_with?("Path") ? Path.value(payload[compare_key], context, input) : payload[compare_key]
          end
        end
      end
    end
  end
end
