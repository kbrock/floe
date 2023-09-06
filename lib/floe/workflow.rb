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

    attr_reader :context, :credentials, :payload, :states, :states_by_name, :start_at

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
    rescue JSON::ParserError => err
      raise Floe::InvalidWorkflowError, err.message
    end

    def run!
      until end?
        step
      end
      self
    end

    def step
      loop until step_nonblock == 0
      self
    end

    def run_async!
      step_nonblock(:timeout => 0)
      self
    end

    def step_nonblock(timeout: 5)
      return Errno::EPERM if end?
      step_nonblock_submit unless current_state.started?

      result = step_nonblock_wait(:timeout => timeout)
      return result if result == Errno::EAGAIN

      step_nonblock_finish
    end

    def step_nonblock_submit
      raise "State is already running" if current_state.started?

      start_time = Time.now.utc

      context.execution["StartTime"] ||= start_time
      context.state["Input"]         ||= context.execution["Input"].dup
      context.state["Guid"]            = SecureRandom.uuid
      context.state["EnteredTime"]     = start_time

      logger.info("Running state: [#{context.state_name}] with input [#{context.input}]...")

      current_state.run_async!(context.state["Input"])
    end

    def step_nonblock_wait(timeout: 5)
      return 0 if step_nonblock_ready?

      sleep(timeout)
      Errno::EAGAIN
    end

    def step_nonblock_ready?
      !current_state.started? || !current_state.running?
    end

    def step_nonblock_finish
      current_state.finish_async
      context.state["FinishedTime"] = Time.now.utc
      context.state["Duration"]     = context.state["FinishedTime"] - context.state["EnteredTime"]
      context.state["Error"]        = current_state.error if current_state.respond_to?(:error)
      context.state["Cause"]        = current_state.cause if current_state.respond_to?(:cause)
      context.execution["EndTime"]  = Time.now.utc if context.next_state.nil?

      logger.info("Running state: [#{context.state_name}] with input [#{context.input}]...Complete - next state: [#{context.next_state}] output: [#{context.output}]")

      context.state_history << context.state

      context.state = {"Name" => context.next_state, "Input" => context.output} unless end?

      0
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

    def current_state
      @states_by_name[context.state_name]
    end
  end
end
