# frozen_string_literal: true

require "securerandom"
require "json"

module Floe
  class Workflow
    include Logging

    class << self
      def load(path_or_io, context = nil, credentials = {})
        payload = path_or_io.respond_to?(:read) ? path_or_io.read : File.read(path_or_io)
        new(payload, context, credentials)
      end
    end

    attr_reader :context, :credentials, :payload, :states, :states_by_name, :current_state, :start_at

    def initialize(payload, context = nil, credentials = {})
      payload     = JSON.parse(payload)     if payload.kind_of?(String)
      credentials = JSON.parse(credentials) if credentials.kind_of?(String)
      context     = Context.new(context)    unless context.kind_of?(Context)

      @payload     = payload
      @context     = context
      @credentials = credentials
      @start_at    = payload["StartAt"]

      @states         = payload["States"].to_a.map { |name, state| State.build!(self, name, state) }
      @states_by_name = @states.each_with_object({}) { |state, result| result[state.name] = state }

      context.state["Name"] ||= start_at

      current_state_name = context.state["Name"]
      @current_state     = @states_by_name[current_state_name]
    rescue JSON::ParserError => err
      raise Floe::InvalidWorkflowError, err.message
    end

    def step
      context.execution["StartTime"] ||= Time.now.utc

      context.state["Guid"]    = SecureRandom.uuid
      context.state["Input"] ||= context.execution["Input"].dup

      logger.info("Running state: [#{current_state.name}] with input [#{context.state["Input"]}]...")

      context.state["EnteredTime"] = Time.now.utc

      tick = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next_state, output = current_state.run!(context.state["Input"])
      tock = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      context.state["FinishedTime"] = Time.now.utc
      context.state["Duration"]     = tock - tick
      context.state["Output"]       = output
      context.state["Error"]        = current_state.error if current_state.respond_to?(:error)
      context.state["Cause"]        = current_state.cause if current_state.respond_to?(:cause)
      context.execution["EndTime"]  = Time.now.utc if next_state.nil?

      logger.info("Running state: [#{current_state.name}] with input [#{context["Input"]}]...Complete - next state: [#{next_state}] output: [#{output}]")

      context.state_history << context.state

      @current_state = next_state && @states_by_name[next_state]

      context.state = {"Name" => next_state, "Input" => output} unless end?

      self
    end

    def run!
      until end?
        step
      end
      self
    end

    def status
      context.status
    end

    def output
      context.output
    end

    def end?
      context.ended?
    end
  end
end
