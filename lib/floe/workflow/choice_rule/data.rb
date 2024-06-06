# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class Data < Floe::Workflow::ChoiceRule
        TYPES       = ["String", "Numeric", "Boolean", "Timestamp", "Present", "Null"].freeze
        OPERATIONS  = ["Equals", "LessThan", "GreaterThan", "LessThanEquals", "GreaterThanEquals", "Matches"].freeze
        UNARY_RULE  = /^(Is)(#{TYPES.join("|")})$/.freeze
        BINARY_RULE = /^(#{(TYPES - %w[Null Present]).join("|")})(#{OPERATIONS.join("|")})(Path)?$/.freeze

        attr_reader :compare_key, :type, :value, :path

        def initialize(*)
          super

          @compare_key = payload.keys.detect { |key| key.match?(UNARY_RULE) || key.match?(BINARY_RULE) }
          payload.error!("requires compare_key field") if @compare_key.nil?

          operator, @type = UNARY_RULE.match(compare_key)&.captures
          if operator
            @path = false
            @value = payload.boolean!(compare_key)
          else
            @type, _operator, @path = BINARY_RULE.match(compare_key)&.captures
            @value = @path ? payload.path!(compare_key) : payload[compare_key]
          end
        end

        def true?(context, input)
          lhs = variable_value(context, input)
          rhs = compare_value(context, input)

          case compare_key
          when "IsNull" then is_null?(lhs)
          when "IsPresent" then is_present?(lhs)
          when "IsNumeric" then is_numeric?(lhs)
          when "IsString" then is_string?(lhs)
          when "IsBoolean" then is_boolean?(lhs)
          when "IsTimestamp" then is_timestamp?(lhs)
          when "StringEquals", "StringEqualsPath",
               "NumericEquals", "NumericEqualsPath",
               "BooleanEquals", "BooleanEqualsPath",
               "TimestampEquals", "TimestampEqualsPath"
            eq?(lhs, rhs)
          when "StringLessThan", "StringLessThanPath",
               "NumericLessThan", "NumericLessThanPath",
               "TimestampLessThan", "TimestampLessThanPath"
            lt?(lhs, rhs)
          when "StringGreaterThan", "StringGreaterThanPath",
               "NumericGreaterThan", "NumericGreaterThanPath",
               "TimestampGreaterThan", "TimestampGreaterThanPath"
            gt?(lhs, rhs)
          when "StringLessThanEquals", "StringLessThanEqualsPath",
               "NumericLessThanEquals", "NumericLessThanEqualsPath",
               "TimestampLessThanEquals", "TimestampLessThanEqualsPath"
            lte?(lhs, rhs)
          when "StringGreaterThanEquals", "StringGreaterThanEqualsPath",
               "NumericGreaterThanEquals", "NumericGreaterThanEqualsPath",
               "TimestampGreaterThanEquals", "TimestampGreaterThanEqualsPath"
            gte?(lhs, rhs)
          when "StringMatches"
            matches?(lhs, rhs)
          end
        end

        private

        def is_null?(value) # rubocop:disable Naming/PredicateName
          value.nil?
        end

        def is_present?(value) # rubocop:disable Naming/PredicateName
          !value.nil?
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
          return false if value.nil?

          require "date"

          DateTime.rfc3339(value)
          true
        rescue TypeError, Date::Error
          false
        end

        def eq?(lhs, rhs)
          is_present?(lhs) && is_present?(rhs) && lhs == rhs
        end

        def lt?(lhs, rhs)
          is_present?(lhs) && is_present?(rhs) && lhs < rhs
        end

        def gt?(lhs, rhs)
          is_present?(lhs) && is_present?(rhs) && lhs > rhs
        end

        def lte?(lhs, rhs)
          is_present?(lhs) && is_present?(rhs) && lhs <= rhs
        end

        def gte?(lhs, rhs)
          is_present?(lhs) && is_present?(rhs) && lhs >= rhs
        end

        def matches?(lhs, rhs)
          is_string?(lhs) && is_string?(rhs) &&
            lhs.match?(Regexp.escape(rhs).gsub('\*', '.*?'))
        end

        def compare_value(context, input)
          path ? value.value(context, input) : value
        end
      end
    end
  end
end
