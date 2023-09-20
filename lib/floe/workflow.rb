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

      def wait(workflows, timeout: 5)
        logger.info("checking #{workflows.count} workflows...")

        start = Time.now.utc
        ready = []

        loop do
          ready = workflows.select(&:step_nonblock_ready?)
          break if timeout.zero? || Time.now.utc - start > timeout || !ready.empty?

          sleep(1)
        end

        logger.info("checking #{workflows.count} workflows...Complete - #{ready.count} ready")
        ready
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

      unless context.state.key?("Name")
        context.state["Name"] = start_at
        context.state["Input"] = context.execution["Input"].dup
      end
    rescue JSON::ParserError => err
      raise Floe::InvalidWorkflowError, err.message
    end

    def run!
      step until end?
      self
    end

    def step
      step_nonblock_wait until step_nonblock == 0
      self
    end

    def run_nonblock
      loop while step_nonblock == 0 && !end?
      self
    end

    def step_nonblock
      return Errno::EPERM if end?

      step_nonblock_start unless current_state.started?
      return Errno::EAGAIN unless step_nonblock_ready?

      step_nonblock_finish
    end

    def step_nonblock_wait(timeout: 5)
      start = Time.now.utc

      loop do
        return 0             if step_nonblock_ready?
        return Errno::EAGAIN if timeout.zero? || Time.now.utc - start > timeout

        sleep(1)
      end
    end

    def step_nonblock_ready?
      !current_state.started? || !current_state.running?
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

    private

    def step_nonblock_start
      raise "State is already running" if current_state.started?

      start_time = Time.now.utc

      context.execution["StartTime"] ||= start_time
      context.state["Guid"]            = SecureRandom.uuid
      context.state["EnteredTime"]     = start_time

      logger.info("Running state: [#{context.state_name}] with input [#{context.input}]...")

      current_state.start(context.state["Input"])
    end

    def step_nonblock_finish
      current_state.finish
      context.state["Duration"]    = context.state["FinishedTime"] - context.state["EnteredTime"]
      context.execution["EndTime"] = Time.now.utc if context.next_state.nil?

      logger.info("Running state: [#{context.state_name}] with input [#{context.input}]...Complete - next state: [#{context.next_state}] output: [#{context.output}]")

      context.state_history << context.state

      context.state = {"Name" => context.next_state, "Input" => context.output} unless end?

      0
    end
  end
end
