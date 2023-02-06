# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Succeed < ManageIQ::Floe::Workflow::State
          attr_reader :input_path, :output_path

          def initialize(workflow, name, payload)
            super

            @input_path  = Path.new(payload.fetch("InputPath", "$"), context)
            @output_path = Path.new(payload.fetch("OutputPath", "$"), context)
          end

          def end?
            true # TODO: Handle if this is ending a parallel or map state
          end

          private def to_dot_attributes
            super.merge(:color => "green")
          end
        end
      end
    end
  end
end
