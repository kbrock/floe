# frozen_string_literal: true

require_relative "floe/version"
require_relative "floe/workflow"
require_relative "floe/workflow/state"
require_relative "floe/workflow/states/choice"
require_relative "floe/workflow/states/fail"
require_relative "floe/workflow/states/pass"
require_relative "floe/workflow/states/succeed"
require_relative "floe/workflow/states/task"
require_relative "floe/workflow/states/wait"

module ManageIQ
  module Floe
    class Error < StandardError; end
    class InvalidWorkflowError < Error; end
  end
end
