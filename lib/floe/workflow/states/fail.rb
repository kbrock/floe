# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Fail < Floe::Workflow::State
        attr_reader :cause, :error

        def initialize(workflow, name, payload)
          super

          @cause = payload["Cause"]
          @error = payload["Error"]
        end

        def start(input)
          super
          context.state["Error"] = error
          context.state["Cause"] = cause
          context.next_state     = nil
          context.output         = input
        end

        def running?
          false
        end

        def end?
          true
        end
      end
    end
  end
end
