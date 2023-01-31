# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      module States
        class Parallel < ManageIQ::Floe::Workflow::State
          def initialize(*)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
