# frozen_string_literal: true

require 'logger'

module Floe
  class NullLogger < Logger
    def initialize(*)
    end

    def add(*_args, &_block)
    end
  end
end
