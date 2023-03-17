# frozen_string_literal: true

module Floe
  class Workflow
    module States
      class Parallel < Floe::Workflow::State
        def initialize(*)
          raise NotImplementedError
        end
      end
    end
  end
end
