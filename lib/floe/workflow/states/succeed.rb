# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Succeed < Floe::Workflow::State
        attr_reader :input_path, :output_path

        def initialize(workflow, name, payload)
          super
        end

        def start(input)
          context.next_state = nil
          context.output     = input
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
