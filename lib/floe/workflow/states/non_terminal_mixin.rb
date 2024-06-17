# frozen_string_literal: true

module Floe
  class Workflow
    module States
      module NonTerminalMixin
        def finish
          # If this state is failed or this is an end state, next_state to nil
          context.next_state ||= end? || context.failed? ? nil : @next

          super
        end

        def validate_state_next!(workflow)
          raise Floe::InvalidWorkflowError, "Missing \"Next\" field in state [#{name}]" if @next.nil? && !@end
          raise Floe::InvalidWorkflowError, "\"Next\" [#{@next}] not in \"States\" for state [#{name}]" if @next && !workflow.payload["States"].key?(@next)
        end
      end
    end
  end
end
