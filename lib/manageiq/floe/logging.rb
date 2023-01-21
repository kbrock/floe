# frozen_string_literal: true

module ManageIQ
  module Floe
    module Logging
      def self.included(base)
        base.extend(self)
      end

      def logger
        ManageIQ::Floe.logger
      end
    end
  end
end
