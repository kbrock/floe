# frozen_string_literal: true

module Floe
  module Logging
    def self.included(base)
      base.extend(self)
    end

    def logger
      Floe.logger
    end
  end
end
