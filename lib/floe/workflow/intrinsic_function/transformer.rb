# Disable rubocops against the `match` method, since this is a Parslet specific
#   match method and not the typical `Object#match`.
# rubocop:disable Performance/RegexpMatch, Performance/RedundantMatch

require "parslet"
require "jsonpath"
require "securerandom"

module Floe
  class Workflow
    module IntrinsicFunction
      class Transformer < Parslet::Transform
        rule(:null_literal  => simple(:v)) { nil }
        rule(:true_literal  => simple(:v)) { true }
        rule(:false_literal => simple(:v)) { false }

        rule(:string   => simple(:v)) { v.to_s }
        rule(:number   => simple(:v)) { v.match(/[eE.]/) ? Float(v) : Integer(v) }
        rule(:jsonpath => simple(:v)) do
          results = JsonPath.on(input, v.to_s)
          results.count < 2 ? results.first : results
        end

        rule(:states_array => subtree(:args)) { args.kind_of?(Array) ? args : [args] }
        rule(:states_uuid  => subtree(:args)) { SecureRandom.uuid }
      end
    end
  end
end

# rubocop:enable Performance/RegexpMatch, Performance/RedundantMatch
