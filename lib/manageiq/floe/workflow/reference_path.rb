# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ReferencePath < Path
        class << self
          def set (payload, context, value)
            new(payload, context).set(value)
          end
        end

        def initialize(*)
          require "more_core_extensions/core_ext/hash/nested"
          require "more_core_extensions/core_ext/array/nested"

          super

          raise ManageIQ::Floe::InvalidWorkflowError, "Invalid Reference Path" if payload.match?(/@|,|:|\?/)
        end

        def set(value)
          path = JsonPath.new(payload)
                         .path[1..]
                         .map { |v| v.match(/\[(?<name>.+)\]/)["name"] }
                         .map { |v| v[0] == "'" ? v.gsub("'", "") : v.to_i }
                         .compact

          # If the payload is '$' then merge the value into the context
          # otherwise use store path to set the value to a sub-key
          #
          # TODO: how to handle non-hash values, raise error if path=$ and value not a hash?
          if path.empty?
            context.merge!(value)
          else
            context.store_path(path, value)
          end
        end
      end
    end
  end
end
