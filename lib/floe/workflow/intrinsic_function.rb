require "parslet"

module Floe
  class Workflow
    class IntrinsicFunction
      def self.value(payload, context = {}, input = {})
        new(payload).value(context, input)
      end

      def self.intrinsic_function?(payload)
        payload.start_with?("States.")
      end

      attr_reader :payload

      def initialize(payload)
        @payload = payload
      end

      def value(context = {}, input = {})
        begin
          tree = Parser.new.parse(payload)
        rescue Parslet::ParseFailed => err
          raise Floe::InvalidWorkflowError, err.message
        end

        Floe.logger.debug { "Parsed intrinsic function: #{payload.inspect} => #{tree.inspect}" }

        Transformer.new.apply(tree, :context => context, :input => input)
      end
    end
  end
end
