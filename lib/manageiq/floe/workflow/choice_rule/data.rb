# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ChoiceRule
        class Data < ManageIQ::Floe::Workflow::ChoiceRule
          def true?
            case compare_key
            when "IsNull"
              variable_value.nil?
            when "IsPresent"
              !variable_value.nil?
            when "IsNumeric"
              variable_value.kind_of?(Integer) || variable_value.kind_of?(Float)
            when "IsString"
              variable_value.kind_of?(String)
            when "IsBoolean"
              [true, false].include?(variable_value)
            when "IsTimestamp"
              require "date"

              begin
                DateTime.rfc3339(variable_value)
                true
              rescue TypeError, Date::Error
                false
              end
            else
              raise RuntimeError, "No such variable [#{variable}]" if variable_value.nil?

              _datatype, comparison = compare_key.match(/^(String|Numeric|Boolean|Timestamp)(Equals|LessThanEquals|GreaterThanEquals|LessThan|GreaterThan|Matches)/).captures
              case comparison
              when "Equals"
                variable_value == compare_value
              when "LessThan"
                variable_value < compare_value
              when "GreaterThan"
                variable_value > compare_value
              when "LessThanEquals"
                variable_value <= compare_value
              when "GreaterThanEquals"
                variable_value >= compare_value
              when "Matches"
                variable_value.match?(Regexp.escape(compare_value).gsub('\*','.*?'))
              else
                raise ManageIQ::Floe::InvalidWorkflowError, "Invalid choice [#{compare_key}]"
              end
            end
          end

          private

          def compare_key
            @compare_key ||= payload.keys.detect { |key| key.match?(/^(IsNull|IsPresent|IsNumeric|IsString|IsBoolean|IsTimestamp|String|Numeric|Boolean|Timestamp)/) }
          end

          def compare_value
            @compare_value ||= compare_key.end_with?("Path") ? JsonPath.on(context, payload[compare_key]).first : payload[compare_key]
          end
        end
      end
    end
  end
end
