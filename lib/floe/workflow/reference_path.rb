# frozen_string_literal: true

module Floe
  class Workflow
    class ReferencePath < Path
      class << self
        def set(payload, context, value)
          new(payload).set(context, value)
        end
      end

      def initialize(*)
        super

        raise Floe::InvalidWorkflowError, "Invalid Reference Path" if payload.match?(/@|,|:|\?/)
      end

      def set(context, value)
        result = context.dup

        path = JsonPath.new(payload)
                       .path[1..]
                       .map { |v| v.match(/\[(?<name>.+)\]/)["name"] }
                       .map { |v| v[0] == "'" ? v.delete("'") : v.to_i }
                       .compact

        # If the payload is '$' then merge the value into the context
        # otherwise use store path to set the value to a sub-key
        #
        # TODO: how to handle non-hash values, raise error if path=$ and value not a hash?
        if path.empty?
          result.merge!(value)
        else
          child = result
          path[..-2].each do |key|
            child[key] = {} if child[key].nil?
            child = child[key]
          end
          child[path.last] = value
        end

        result
      end
    end
  end
end
