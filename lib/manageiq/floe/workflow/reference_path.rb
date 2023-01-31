# frozen_string_literal: true

module ManageIQ
  module Floe
    class Workflow
      class ReferencePath < Path
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

          context.store_path(path, value)
        end
      end
    end
  end
end
