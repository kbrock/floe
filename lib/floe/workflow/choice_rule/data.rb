# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class Data < Floe::Workflow::ChoiceRule
        def true?(context, input)
          return presence_check(context, input) if compare_key == "IsPresent"

          lhs = variable_value(context, input)
          rhs = compare_value(context, input)

          case compare_key
          when "IsNull" then is_null?(lhs)
          when "IsNumeric" then is_numeric?(lhs)
          when "IsString" then is_string?(lhs)
          when "IsBoolean" then is_boolean?(lhs)
          when "IsTimestamp" then is_timestamp?(lhs)
          when "StringEquals", "StringEqualsPath",
               "NumericEquals", "NumericEqualsPath",
               "BooleanEquals", "BooleanEqualsPath",
               "TimestampEquals", "TimestampEqualsPath"
            lhs == rhs
          when "StringLessThan", "StringLessThanPath",
               "NumericLessThan", "NumericLessThanPath",
               "TimestampLessThan", "TimestampLessThanPath"
            lhs < rhs
          when "StringGreaterThan", "StringGreaterThanPath",
               "NumericGreaterThan", "NumericGreaterThanPath",
               "TimestampGreaterThan", "TimestampGreaterThanPath"
            lhs > rhs
          when "StringLessThanEquals", "StringLessThanEqualsPath",
               "NumericLessThanEquals", "NumericLessThanEqualsPath",
               "TimestampLessThanEquals", "TimestampLessThanEqualsPath"
            lhs <= rhs
          when "StringGreaterThanEquals", "StringGreaterThanEqualsPath",
               "NumericGreaterThanEquals", "NumericGreaterThanEqualsPath",
               "TimestampGreaterThanEquals", "TimestampGreaterThanEqualsPath"
            lhs >= rhs
          when "StringMatches"
            lhs.match?(Regexp.escape(rhs).gsub('\*', '.*?'))
          else
            raise Floe::InvalidWorkflowError, "Invalid choice [#{compare_key}]"
          end
        end

        private

        def presence_check(context, input)
          rhs = compare_value(context, input)
          # don't need the value, just need to see if the path finds the value
          variable_value(context, input)

          # path found the variable_value, (so if they said true, return true)
          rhs
        rescue Floe::PathError
          # variable_value (path) threw an error
          # it was not found (so if they said false, return true)
          !rhs
        end

        def is_null?(value) # rubocop:disable Naming/PredicateName
          value.nil?
        end

        # if it got here (and value was fetched), then it is present.
        def is_present?(_value) # rubocop:disable Naming/PredicateName
          true
        end

        def is_numeric?(value) # rubocop:disable Naming/PredicateName
          value.kind_of?(Integer) || value.kind_of?(Float)
        end

        def is_string?(value) # rubocop:disable Naming/PredicateName
          value.kind_of?(String)
        end

        def is_boolean?(value) # rubocop:disable Naming/PredicateName
          [true, false].include?(value)
        end

        def is_timestamp?(value) # rubocop:disable Naming/PredicateName
          require "date"

          DateTime.rfc3339(value)
          true
        rescue TypeError, Date::Error
          false
        end

        def compare_key
          @compare_key ||= payload.keys.detect { |key| key.match?(/^(IsNull|IsPresent|IsNumeric|IsString|IsBoolean|IsTimestamp|String|Numeric|Boolean|Timestamp)/) }
        end

        def compare_value(context, input)
          compare_key.end_with?("Path") ? Path.value(payload[compare_key], context, input) : payload[compare_key]
        end
      end
    end
  end
end
