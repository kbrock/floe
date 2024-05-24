# Disable rubocops against the `match` method, since this is a Parslet specific
#   match method and not the typical `Object#match`.
# rubocop:disable Performance/RegexpMatch, Performance/RedundantMatch

require "parslet"

module Floe
  class Workflow
    module IntrinsicFunction
      class Transformer < Parslet::Transform
        rule(:null_literal  => simple(:v)) { nil }
        rule(:true_literal  => simple(:v)) { true }
        rule(:false_literal => simple(:v)) { false }

        rule(:string   => simple(:v)) { v.to_s }
        rule(:number   => simple(:v)) { v.match(/[eE.]/) ? Float(v) : Integer(v) }

        rule(:states_array => subtree(:args)) { args.kind_of?(Array) ? args : [args] }
      end
    end
  end
end

# rubocop:enable Performance/RegexpMatch, Performance/RedundantMatch
