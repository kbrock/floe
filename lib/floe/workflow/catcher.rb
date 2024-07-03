# frozen_string_literal: true

module Floe
  class Workflow
    class Catcher
      include ErrorMatcherMixin
      include ValidationMixin

      attr_reader :error_equals, :next, :result_path, :name

      def initialize(_workflow, name, payload)
        @name         = name
        @payload      = payload

        @error_equals = payload["ErrorEquals"]
        @next         = payload["Next"]
        @result_path  = ReferencePath.new(payload.fetch("ResultPath", "$"))

        missing_field_error!("ErrorEquals") if !@error_equals.kind_of?(Array) || @error_equals.empty?
      end
    end
  end
end
