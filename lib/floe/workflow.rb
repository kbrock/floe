# frozen_string_literal: true

require "securerandom"
require "json"

module Floe
  class Workflow
    include Logging
    include ValidationMixin

    class << self
      # @param [String|IO] path_or_io filename path or stream object
      # @param [String|nil] context
      # @param [String|nil] credentials
      # @param [String|nil] name (defaults to path_or_io filename if it is a filename)
      def load_from_file(path_or_io, context = nil, input: "{}", credentials: nil, name: nil)
        payload = path_or_io.respond_to?(:read) ? path_or_io.read : File.read(path_or_io)
        # default the name if it is a filename and none was passed in
        name ||= path_or_io.respond_to?(:read) ? "stream" : path_or_io.split("/").last.split(".").first

        ctx = Context.from_strings(context, :input => input, :credentials => credentials)
        new(payload, ctx, :name => name)
      end

      # @param [Hash] payload
      # @param [Hash] context
      # @param [Hash] credentials
      def load(payload, context, credentials, name: nil)
        new(payload.to_json, context, credentials, :name => name)
      end

      def wait(workflows, timeout: nil, &block)
        workflows = [workflows] if workflows.kind_of?(self)
        logger.info("checking #{workflows.count} workflows...")

        run_until   = Time.now.utc + timeout if timeout.to_i > 0
        ready       = []
        queue       = Queue.new
        wait_thread = Thread.new do
          loop do
            Runner.for_resource("docker").wait do |event, runner_context|
              queue.push([event, runner_context])
            end
          end
        end

        loop do
          ready = workflows.select(&:step_nonblock_ready?)
          break if block.nil? && !ready.empty?

          ready.each(&block)

          # Break if all workflows are completed or we've exceeded the
          # requested timeout
          break if workflows.all?(&:end?)
          break if timeout && (timeout.zero? || Time.now.utc > run_until)

          # Find the earliest time that we should wakeup if no container events
          # are caught, either a workflow in a Wait or Retry state or we've
          # exceeded the requested timeout
          wait_until = workflows.map(&:wait_until)
                                .unshift(run_until)
                                .compact
                                .min

          # If a workflow is in a waiting state wakeup the main thread when
          # it will be done sleeping
          if wait_until
            sleep_thread = Thread.new do
              sleep_duration = wait_until - Time.now.utc
              sleep sleep_duration if sleep_duration > 0
              queue.push(nil)
            end
          end

          loop do
            # Block until an event is raised
            event, runner_context = queue.pop
            break if event.nil?

            # If the event is for one of our workflows set the updated runner_context
            workflows.each do |workflow|
              next unless workflow.context.state.dig("RunnerContext", "container_ref") == runner_context["container_ref"]

              workflow.context.state["RunnerContext"] = runner_context
            end

            break if queue.empty?
          end
        ensure
          sleep_thread&.kill
        end

        logger.info("checking #{workflows.count} workflows...Complete - #{ready.count} ready")
        ready
      ensure
        wait_thread&.kill
      end
    end

    attr_reader :context, :payload, :states, :states_by_name, :start_at, :name, :comment

    # @param [Json String|Hash|Array] payload
    # @param [Context|Hash] context
    # @param [Hash|String|nil] credentials injects into credentials
    # @param [String|nil] name (defaults to State Machine)
    def initialize(payload, context = nil, credentials = nil, name: nil)
      payload     = JSON.parse(payload)     if payload.kind_of?(String)
      credentials = JSON.parse(credentials) if credentials.kind_of?(String)
      context     = Context.new(context)    unless context.kind_of?(Context)

      # backwards compatibility
      # caller should really put credentials into context and not pass that variable
      context.credentials = credentials if credentials

      # NOTE: this is a string, and states use an array
      @name        = name || "State Machine"
      @payload     = payload
      @context     = context
      @comment     = payload["Comment"]
      @start_at    = payload["StartAt"]

      # NOTE: Everywhere else we include our name (i.e.: parent name) when building the child name.
      #       When creating the states, we are dropping our name (i.e.: the workflow name)
      @states      = payload["States"].to_a.map { |state_name, state| State.build!(self, ["States", state_name], state) }

      validate_workflow

      @states_by_name = @states.each_with_object({}) { |state, result| result[state.short_name] = state }
    rescue Floe::Error
      raise
    rescue => err
      raise Floe::InvalidWorkflowError, err.message
    end

    def run_nonblock
      start_workflow
      loop while step_nonblock == 0 && !end?
      self
    end

    # NOTE: If running manually, make sure to call start_workflow at startup
    def step_nonblock
      return Errno::EPERM if end?

      result = current_state.run_nonblock!(context)
      return result if result != 0

      # if it completed the step
      context.state_history << context.state
      context.next_state ? step! : end_workflow!

      result
    end

    # if this hasn't started (and we have no current_state yet), assume it is ready
    def step_nonblock_wait(timeout: nil)
      context.started? ? current_state.wait(context, :timeout => timeout) : 0
    end

    # if this hasn't started (and we have no current_state yet), assume it is ready
    def step_nonblock_ready?
      !context.started? || current_state.ready?(context)
    end

    def waiting?
      current_state.waiting?(context)
    end

    def wait_until
      current_state.wait_until(context)
    end

    def status
      context.status
    end

    def output
      context.json_output if end?
    end

    def end?
      context.ended?
    end

    # setup a workflow
    def start_workflow
      return if context.state_name

      context.state["Name"]  = start_at
      context.state["Input"] = context.execution["Input"].dup
      context.state["Guid"]  = SecureRandom.uuid

      context.execution["Id"]        = SecureRandom.uuid
      context.execution["StartTime"] = Time.now.utc.iso8601

      self
    end

    # NOTE: Expecting the context to be initialized (via start_workflow) before this
    def current_state
      @states_by_name[context.state_name]
    end

    # backwards compatibility. Caller should access directly from context
    def credentials
      @context.credentials
    end

    private

    def validate_workflow
      missing_field_error!("States") if @states.empty?
      missing_field_error!("StartAt") if @start_at.nil?
      invalid_field_error!("StartAt", @start_at, "is not found in \"States\"") unless workflow_state?(@start_at, self)
    end

    def step!
      next_state = {"Name" => context.next_state, "Guid" => SecureRandom.uuid, "PreviousStateGuid" => context.state["Guid"]}

      # if rerunning due to an error (and we are using Retry)
      if context.state_name == context.next_state && context.failed? && context.state.key?("Retrier")
        next_state.merge!(context.state.slice("RetryCount", "Input", "Retrier"))
      else
        next_state["Input"] = context.output
      end

      context.state = next_state
    end

    def end_workflow!
      context.execution["EndTime"] = context.state["FinishedTime"]
    end
  end
end
