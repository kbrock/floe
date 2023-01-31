# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ReferencePath < Path
        def initialize(*)
          super

          raise ManageIQ::Floe::InvalidWorkflowError, "Invalid Reference Path" if payload.match?(/@|,|:|\?/)
        end
      end
    end
  end
end
