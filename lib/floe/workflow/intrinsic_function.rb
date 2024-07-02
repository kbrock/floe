require "parslet"

module Floe
  class Workflow
    module IntrinsicFunction
      def self.evaluate(payload, context = {}, input = {})
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
