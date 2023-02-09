# frozen_string_literal: true

require "json"

module ManageIQ
  module Floe
    class Workflow
      class << self
        def load(path_or_io, context = {}, credentials = {})
          payload = path_or_io.respond_to?(:read) ? path_or_io.read : File.read(path_or_io)
          new(payload, context, credentials)
        end
      end

      attr_reader :context, :credentials, :first_state, :payload, :states, :states_by_name, :start_at

      def initialize(payload, context = {}, credentials = {})
        payload     = JSON.parse(payload)     if payload.kind_of?(String)
        context     = JSON.parse(context)     if context.kind_of?(String)
        credentials = JSON.parse(credentials) if credentials.kind_of?(String)

        @payload        = payload
        @context        = context
        @credentials    = credentials
        @states         = parse_states
        @states_by_name = states.each_with_object({}) { |state, result| result[state.name] = state }
        @start_at       = @payload["StartAt"]
        @first_state    = @states_by_name[@start_at]
      rescue JSON::ParserError => err
        raise ManageIQ::Floe::InvalidWorkflowError, err.message
      end

      def to_dot
        String.new.tap do |s|
          s << "digraph {\n"
          states.each do |state|
            s << state.to_dot << "\n"
          end
          s << "\n"
          states.each do |state|
            Array(state.to_dot_transitions).each do |transition|
              s << transition << "\n"
            end
          end
          s << "}\n"
        end
      end

      def to_svg(path: nil)
        require "open3"
        out, err, _status = Open3.capture3("dot -Tsvg", :stdin_data => to_dot)

        raise "Error from graphviz:\n#{err}" if err && !err.empty?

        File.write(path, out) if path

        out
      end

      def to_ascii(path: nil)
        require "open3"
        out, err, _status = Open3.capture3("graph-easy", :stdin_data => to_dot)

        raise "Error from graph-easy:\n#{err}" if err && !err.empty?

        File.write(path, out) if path

        out
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
