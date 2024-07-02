# Disable rubocops against the `match` method, since this is a Parslet specific
#   match method and not the typical `Object#match`.
# rubocop:disable Performance/RegexpMatch, Performance/RedundantMatch

require "parslet"
require "securerandom"

module Floe
  class Workflow
    class IntrinsicFunction
      class Transformer < Parslet::Transform
        def self.resolve_args(args)
          if args.nil?
            # 0 args
            []
          elsif args.kind_of?(Array)
            # >1 arg
            args.map { |a| a[:arg] }
          else
            # 1 arg
            [args[:arg]]
          end
        end

        rule(:null_literal  => simple(:v)) { nil }
        rule(:true_literal  => simple(:v)) { true }
        rule(:false_literal => simple(:v)) { false }

        rule(:string   => simple(:v)) { v.to_s }
        rule(:number   => simple(:v)) { v.match(/[eE.]/) ? Float(v) : Integer(v) }
        rule(:jsonpath => simple(:v)) { Floe::Workflow::Path.value(v.to_s, context, input) }

        rule(:states_array => {:args => subtree(:args)}) { Transformer.resolve_args(args) }

        rule(:states_uuid  => subtree(:args)) { SecureRandom.uuid }
      end
    end
  end
end

# rubocop:enable Performance/RegexpMatch, Performance/RedundantMatch
