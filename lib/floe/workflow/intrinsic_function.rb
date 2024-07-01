module Floe
  class Workflow
    module IntrinsicFunction
      def self.evaluate(payload, input = {})
        tree = Parser.new.parse(payload)
        pp tree if ENV["DEBUG"]
        Transformer.new.apply(tree, :input => input)
      end
    end
  end
end
