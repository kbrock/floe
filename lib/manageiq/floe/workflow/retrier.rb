# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class Retrier
        attr_reader :error_equals, :interval_seconds, :max_attempts, :backoff_rate

        def initialize(payload)
          @payload = payload

          @error_equals     = payload["ErrorEquals"]
          @interval_seconds = payload["IntervalSeconds"]
          @max_attempts     = payload["MaxAttempts"]
          @backoff_rate     = payload["BackoffRate"]
        end
      end
    end
  end
end
