# Disable rubocops against the `match` method, since this is a Parslet specific
#   match method and not the typical `Object#match`.
# rubocop:disable Performance/RegexpMatch, Performance/RedundantMatch

require "parslet"
require "securerandom"
require "base64"

module Floe
  class Workflow
    class IntrinsicFunction
      class Transformer < Parslet::Transform
        def self.process_args(args, function, signature = nil)
          # Force args into an array
          args =
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

          if signature
            # Check arity
            raise ArgumentError, "wrong number of arguments to #{function} (given #{args.size}, expected #{signature.size})" unless args.size == signature.size

            # Check types
            args.zip(signature).each_with_index do |(arg, type), index|
              raise ArgumentError, "wrong type for argument #{index + 1} to #{function} (given #{arg.class}, expected #{type})" unless arg.kind_of?(type)
            end
          end

          args
        end

        rule(:null_literal  => simple(:v)) { nil }
        rule(:true_literal  => simple(:v)) { true }
        rule(:false_literal => simple(:v)) { false }

        rule(:string   => simple(:v)) { v.to_s[1..-2] }
        rule(:number   => simple(:v)) { v.match(/[eE.]/) ? Float(v) : Integer(v) }
        rule(:jsonpath => simple(:v)) { Floe::Workflow::Path.value(v.to_s, context, input) }

        rule(:states_array => {:args => subtree(:args)}) do
          Transformer.process_args(args, "States.Array")
        end

        rule(:states_array_partition => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.ArrayPartition", [Array, Integer])
          array, chunk = *args
          raise ArgumentError, "invalid value for argument 2 to States.ArrayPartition (given #{chunk}, expected a positive Integer)" unless chunk.positive?

          array.each_slice(chunk).to_a
        end

        rule(:states_array_contains => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.ArrayContains", [Array, Object])
          array, target = *args

          array.include?(target)
        end

        rule(:states_array_range => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.ArrayRange", [Integer, Integer, Integer])
          range_begin, range_end, increment = *args
          raise ArgumentError, "invalid value for argument 3 to States.ArrayRange (given #{increment}, expected a non-zero Integer)" if increment.zero?

          (range_begin..range_end).step(increment).to_a
        end

        rule(:states_array_get_item => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.ArrayGetItem", [Array, Integer])
          array, index = *args
          raise ArgumentError, "invalid value for argument 2 to States.ArrayGetItem (given #{index}, expected 0 or a positive Integer)" unless index >= 0

          array[index]
        end

        rule(:states_array_length => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.ArrayLength", [Array])
          array = args.first

          array.size
        end

        rule(:states_array_unique => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.ArrayUnique", [Array])
          array = args.first

          array.uniq
        end

        rule(:states_base64_encode => {:args => subtree(:args)}) do
          args = Transformer.process_args(args(), "States.Base64Encode", [String])
          str = args.first

          Base64.strict_encode64(str).force_encoding("UTF-8")
        end

        rule(:states_uuid => {:args => subtree(:args)}) do
          Transformer.process_args(args, "States.UUID", [])

          SecureRandom.uuid
        end
      end
    end
  end
end

# rubocop:enable Performance/RegexpMatch, Performance/RedundantMatch
