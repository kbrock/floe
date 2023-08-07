# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class << self
        def build(payload)
          if (sub_payloads = payload["Not"])
            Floe::Workflow::ChoiceRule::Not.new(payload, build_children([sub_payloads]))
          elsif (sub_payloads = payload["And"])
            Floe::Workflow::ChoiceRule::And.new(payload, build_children(sub_payloads))
          elsif (sub_payloads = payload["Or"])
            Floe::Workflow::ChoiceRule::Or.new(payload, build_children(sub_payloads))
          else
            Floe::Workflow::ChoiceRule::Data.new(payload)
          end
        end

        def build_children(sub_payloads)
          sub_payloads.map { |payload| build(payload) }
        end
      end

      attr_reader :next, :payload, :variable, :children

      def initialize(payload, children = nil)
        @payload   = payload
        @children  = children

        @next     = payload["Next"]
        @variable = payload["Variable"]
      end

      def true?(*)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      private

      def variable_value(context, input)
        Path.value(variable, context, input)
      end
    end
  end
end
