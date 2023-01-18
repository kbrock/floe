# frozen_string_literal: true

require_relative "floe/version"
require_relative "floe/workflow"
require_relative "floe/workflow/state"
require_relative "floe/workflow/state/choice"
require_relative "floe/workflow/state/fail"
require_relative "floe/workflow/state/pass"
require_relative "floe/workflow/state/succeed"
require_relative "floe/workflow/state/task"
require_relative "floe/workflow/state/wait"

module ManageIQ
  module Floe
    class Error < StandardError; end
    class InvalidWorkflowError < Error; end
  end
end
