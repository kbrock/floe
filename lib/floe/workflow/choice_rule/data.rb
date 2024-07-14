# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class Data < Floe::Workflow::ChoiceRule
        TYPES       = ["String", "Numeric", "Boolean", "Timestamp", "Present", "Null"].freeze
        OPERATIONS  = ["Equals", "LessThan", "GreaterThan", "LessThanEquals", "GreaterThanEquals", "Matches"].freeze
        # e.g.: (Is)(String), (Is)(Present)
        UNARY_RULE  = /^(Is)(#{TYPES.join("|")})$/.freeze
        # e.g.: (String)(LessThan)(Path), (Numeric)(GreaterThanEquals)()
        BINARY_RULE = /^(#{(TYPES - %w[Null Present]).join("|")})(#{OPERATIONS.join("|")})(Path)?$/.freeze

        attr_reader :variable, :compare_key, :type, :value, :path

        def initialize(_workflow, _name, payload)
          super

          @variable = parse_path("Variable", payload)
          parse_compare_key
          @value = path ? parse_path(compare_key, payload) : payload[compare_key]
        end

        def true?(context, input)
          return presence_check(context, input) if compare_key == "IsPresent"

          lhs = variable_value(context, input)
          rhs = compare_value(context, input)

          case compare_key
          when "IsNull" then is_null?(lhs, rhs)
          when "IsNumeric" then is_numeric?(lhs, rhs)
          when "IsString" then is_string?(lhs, rhs)
          when "IsBoolean" then is_boolean?(lhs, rhs)
          when "IsTimestamp" then is_timestamp?(lhs, rhs)
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

        # rubocop:disable Naming/PredicateName
        # rubocop:disable Style/OptionalBooleanParameter
        def is_null?(value, ret_value = true)
          value.nil? == ret_value
        end

        # if it got here (and value was fetched), then it is present.
        def is_present?(_value, ret_value = true)
          ret_value
        end

        def is_numeric?(value, ret_value = true)
          value.kind_of?(Numeric) == ret_value
        end

        def is_string?(value, ret_value = true)
          value.kind_of?(String) == ret_value
        end

        def is_boolean?(value, ret_value = true)
          [true, false].include?(value) == ret_value
        end

        def is_timestamp?(value, ret_value = true)
          require "date"

          DateTime.rfc3339(value)
          ret_value
        rescue TypeError, Date::Error
          !ret_value
        end
        # rubocop:enable Naming/PredicateName
        # rubocop:enable Style/OptionalBooleanParameter

        def variable_value(context, input)
          variable.value(context, input)
        end

        def compare_value(context, input)
          path ? value.value(context, input) : value
        end

        def parse_compare_key
          @compare_key = payload.keys.detect { |key| key.match?(UNARY_RULE) || key.match?(BINARY_RULE) }
          parser_error!("requires a compare key") unless compare_key

          @type, _operator, @path = BINARY_RULE.match(compare_key)&.captures
          # since a unary_rule won't match, then @path = @type = nil
        end

        def parse_path(field_name, payload)
          value = payload[field_name]
          missing_field_error!(field_name) unless value
          wrap_parser_error(field_name, value) { Path.new(value) }
        end
      end
    end
  end
end
