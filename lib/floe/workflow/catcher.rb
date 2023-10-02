# frozen_string_literal: true

module Floe
  class Workflow
    class Catcher
      attr_reader :error_equals, :next, :result_path

      def initialize(payload)
        @payload = payload

        @error_equals = payload["ErrorEquals"]
        @next         = payload["Next"]
        @result_path  = ReferencePath.new(payload.fetch("ResultPath", "$"))
      end
    end
  end
end
