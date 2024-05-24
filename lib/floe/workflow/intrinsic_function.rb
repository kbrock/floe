module Floe
  class Workflow
    module IntrinsicFunction
      def self.evaluate(payload, _input = {})
        tree = Parser.new.parse(payload)
        pp tree if ENV["DEBUG"]
        Transformer.new.apply(tree)
      end
    end
  end
end
