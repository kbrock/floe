# frozen_string_literal: true

require 'logger'

module Floe
  class NullLogger < Logger
    def initialize(*) # rubocop:disable Lint/MissingSuper
    end

    def add(*_args, &_block)
    end
  end
end
