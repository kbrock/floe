module Floe
  class Workflow
    module IntrinsicFunction
      def self.evaluate(payload, context = {}, input = {})
        tree = Parser.new.parse(payload)
        pp tree if ENV["DEBUG"]
        Transformer.new.apply(tree, :context => context, :input => input)
      end
    end
  end
end
