# frozen_string_literal: true

require "json"

module ManageIQ
  module Floe
    class Workflow
      class << self
        def load(path_or_io)
          path_or_io = File.open(path_or_io, 'r') if path_or_io.kind_of?(String)
          new(path_or_io.read)
        end
      end

      attr_reader :first_state, :payload, :states, :states_by_name, :start_at

      def initialize(payload)
        @payload        = JSON.parse(payload)
        @states         = parse_states
        @states_by_name = states.each_with_object({}) { |state, result| result[state.name] = state }
        @start_at       = @payload["StartAt"]
        @first_state    = @states_by_name[@start_at]
      rescue JSON::ParserError => err
        raise ManageIQ::Floe::InvalidWorkflowError, err.message
      end

      private

      def parse_states
        payload["States"].map do |name, state_payload|
          State.build!(self, name, state_payload)
        end
      end
    end
  end
end
