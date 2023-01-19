# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class State
        class << self
          def build!(workflow, name, payload)
            state_type = payload["Type"]

            begin
              klass = ManageIQ::Floe::Workflow::States.const_get(state_type)
            rescue NameError
              raise ManageIQ::Floe::InvalidWorkflowError, "Invalid state type: [#{state_type}]"
            end

            klass.new(workflow, name, payload)
          end
        end

        attr_reader :workflow, :comment, :name, :type, :payload

        def initialize(workflow, name, payload)
          @workflow = workflow
          @name     = name
          @payload  = payload
          @type     = payload["Type"]
          @comment  = payload["Comment"]
        end

        def run!
          puts name

          next_state = workflow.states_by_name[payload["Next"]] unless payload["End"]
          outputs = {}

          [next_state, outputs]
        end
      end
    end
  end
end
