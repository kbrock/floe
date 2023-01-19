# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Choice < ManageIQ::Floe::Workflow::State
          def run!
            puts name

            # TODO evaluate the choice, for now just pick the first
            next_state = workflow.states_by_name[payload["Choices"][0]["Next"]]
            results = {}

            [next_state, results]
          end
        end
      end
    end
  end
end
