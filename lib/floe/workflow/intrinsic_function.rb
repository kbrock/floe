module Floe
  class Workflow
    module IntrinsicFunction
      def self.evaluate(payload, context = {}, input = {})
        tree = Parser.new.parse(payload)
        Floe.logger.debug { "Parsed intrinsic function: #{payload.inspect} => #{tree.inspect}" }
        Transformer.new.apply(tree, :context => context, :input => input)
      end
    end
  end
end
