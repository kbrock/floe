# frozen_string_literal: true

require "json"

module Floe
  class Workflow
    class << self
      def load(path_or_io, context = nil, credentials = {})
        payload = path_or_io.respond_to?(:read) ? path_or_io.read : File.read(path_or_io)
        new(payload, context, credentials)
      end
    end

    attr_reader :context, :credentials, :payload, :states, :states_by_name, :current_state, :status

    def initialize(payload, context = nil, credentials = {})
      payload     = JSON.parse(payload)     if payload.kind_of?(String)
      context     = JSON.parse(context)     if context.kind_of?(String)
      credentials = JSON.parse(credentials) if credentials.kind_of?(String)
      context     = Context.new(context)    unless context.kind_of?(Context)

      @payload     = payload
      @context     = context || {"global" => {}}
      @credentials = credentials

      @states         = payload["States"].to_a.map { |name, state| State.build!(self, name, state) }
      @states_by_name = @states.each_with_object({}) { |state, result| result[state.name] = state }
      start_at        = @payload["StartAt"]

      current_state_name = @context["State"]["Name"] || start_at
      @current_state = @states_by_name[current_state_name]

      @status = current_state_name == start_at ? "pending" : current_state.status
    rescue JSON::ParserError => err
      raise Floe::InvalidWorkflowError, err.message
    end

    def step
      @status = "running" if @status == "pending"
      @context["Execution"]["StartTime"] ||= Time.now.utc

      input = @context["State"]["Output"] || @context["Execution"]["Input"].dup

      tick = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next_state, output = current_state.run!(input)
      tock = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @context["State"] = {
        "EnteredTime"  => tick,
        "FinishedTime" => tock,
        "Duration"     => tock - tick,
        "Output"       => output,
        "Name"         => next_state&.name,
        "Input"        => output
      }

      @context["States"] << @context["State"]

      @status = current_state.status

      next_state_name = next_state&.name
      @current_state = next_state_name && @states_by_name[next_state_name]

      self
    end

    def run!
      until end?
        step
      end
      self
    end

    def end?
      current_state.nil?
    end
  end
end
