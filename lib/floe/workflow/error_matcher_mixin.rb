# frozen_string_literal: true

module Floe
  class Workflow
    # Methods for common error handling
    module ErrorMatcherMixin
      # @param [String] error the error thrown
      def match_error?(error)
        return true if error_equals.include?("States.ALL")
        return true if error_equals.include?("States.Timeout") && error == "States.HeartbeatTimeout"

        error_equals.include?(error)
      end
    end
  end
end
