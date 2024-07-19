# frozen_string_literal: true

module Floe
  class Workflow
    class Context
      attr_accessor :credentials

      # @param [Json String|nil] context
      # @param [Json String|nil] input       (default: {})
      # @param [Json String|nil] credentials (default: {})
      def self.from_strings(context, input: "{}", credentials: nil)
        context = context ? JSON.parse(context) : {}
        # input is passed through
        credentials = credentials ? JSON.parse(credentials) : {}

        new(context, :input => input, :credentials => credentials)
      end

      def self.from_hashes(context = {}, input: {}, credentials: {})
        new(context, :input => input.to_json, :credentials => credentials)
      end

      # @param [Json String|Hash] context
      # @param [Json String|nil]  input
      # @param [Hash]             credentials
      def initialize(context = nil, input: nil, credentials: {})
        context = JSON.parse(context) if context.kind_of?(String)
        input   = JSON.parse(input || "{}")

        @context = context || {}
        self["Execution"]          ||= {}
        self["Execution"]["Input"] ||= input
        self["State"]              ||= {}
        self["StateHistory"]       ||= []
        self["StateMachine"]       ||= {}
        self["Task"]               ||= {}

        @credentials = credentials || {}
      rescue JSON::ParserError => err
        raise Floe::InvalidExecutionInput, "Invalid State Machine Execution Input: #{err}: was expecting (JSON String, Number, Array, Object or token 'null', 'true' or 'false')"
      end

      def execution
        @context["Execution"]
      end

      def started?
        execution.key?("StartTime")
      end

      def running?
        started? && !ended?
      end

      def failed?
        (output.kind_of?(Hash) && output.key?("Error")) || false
      end

      def ended?
        execution.key?("EndTime")
      end

      def state
        @context["State"]
      end

      def input
        state["Input"]
      end

      def json_input
        input.to_json
      end

      def output
        state["Output"]
      end

      def json_output
        output.to_json
      end

      def output=(val)
        state["Output"] = val
      end

      def state_name
        state["Name"]
      end

      def next_state
        state["NextState"]
      end

      def next_state=(val)
        state["NextState"] = val
      end

      def status
        if !started?
          "pending"
        elsif running?
          "running"
        elsif failed?
          "failure"
        else
          "success"
        end
      end

      def success?
        status == "success"
      end

      def state_started?
        state.key?("EnteredTime")
      end

      # State#running? also checks docker to see if it is running.
      # You possibly want to use that instead
      def state_finished?
        state.key?("FinishedTime")
      end

      def state=(val)
        @context["State"] = val
      end

      def state_history
        @context["StateHistory"]
      end

      def state_machine
        @context["StateMachine"]
      end

      def task
        @context["Task"]
      end

      def [](key)
        @context[key]
      end

      def []=(key, val)
        @context[key] = val
      end

      def dig(*args)
        @context.dig(*args)
      end

      def to_h
        @context
      end

      def to_json(*args)
        to_h.to_json(*args)
      end
    end
  end
end
