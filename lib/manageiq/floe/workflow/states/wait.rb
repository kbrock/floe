# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Wait < ManageIQ::Floe::Workflow::State
          attr_reader :seconds

          def initialize(workflow, name, payload)
            super

            @seconds = payload["Seconds"]
          end

          def run!
            sleep(seconds)

            super
          end
        end
      end
    end
  end
end
