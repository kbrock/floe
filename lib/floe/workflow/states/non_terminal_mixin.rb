# frozen_string_literal: true

module Floe
  class Workflow
    module States
      module NonTerminalMixin
        def validate_state_next!
          raise Floe::InvalidWorkflowError, "Missing \"Next\" field in state [#{name}]" if @next.nil? && !@end
          raise Floe::InvalidWorkflowError, "\"Next\" [#{@next}] not in \"States\" for state [#{name}]" if @next && !workflow.payload["States"].key?(@next)
        end
      end
    end
  end
end
