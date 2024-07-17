# frozen_string_literal: true

module Floe
  class Workflow
    class ChoiceRule
      class << self
        def build(workflow, name, payload)
          if (sub_payloads = payload["Not"])
            name += ["Not"]
            Floe::Workflow::ChoiceRule::Not.new(workflow, name, payload, build_children(workflow, name, [sub_payloads]))
          elsif (sub_payloads = payload["And"])
            name += ["And"]
            Floe::Workflow::ChoiceRule::And.new(workflow, name, payload, build_children(workflow, name, sub_payloads))
          elsif (sub_payloads = payload["Or"])
            name += ["Or"]
            Floe::Workflow::ChoiceRule::Or.new(workflow, name, payload, build_children(workflow, name, sub_payloads))
          else
            name += ["Data"]
            Floe::Workflow::ChoiceRule::Data.new(workflow, name, payload)
          end
        end

        def build_children(workflow, name, sub_payloads)
          sub_payloads.map.with_index { |payload, i| build(workflow, name + [i.to_s], payload) }
        end
      end

      attr_reader :next, :payload, :children, :name

      def initialize(_workflow, name, payload, children = nil)
        @name      = name
        @payload   = payload
        @children  = children
        @next      = payload["Next"]
      end

      def true?(*)
        raise NotImplementedError, "Must be implemented in a subclass"
      end

      private
    end
  end
end
