# frozen_string_literal: true

require 'logger'

module Floe
  class NullLogger < Logger
    def initialize(*_args)
    end

    def add(*_args, &_block)
    end
  end
end
