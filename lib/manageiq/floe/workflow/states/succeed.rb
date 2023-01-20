# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Succeed < ManageIQ::Floe::Workflow::State
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
