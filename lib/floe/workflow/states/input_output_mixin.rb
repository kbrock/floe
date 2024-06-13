# frozen_string_literal: true

module Floe
  class Workflow
    module States
      module InputOutputMixin
        def process_input(input)
          input = input_path.value(context, input)
          input = parameters.value(context, input) if parameters
          input
        end

        def process_output(input, results)
          return input if results.nil?
          return if output_path.nil?

          results = result_selector.value(context, results) if @result_selector
          if result_path.payload.start_with?("$.Credentials")
            credentials = result_path.set(context.credentials, results)["Credentials"]
            context.credentials.merge!(credentials)
            output = input
          else
            output = result_path.set(input, results)
          end

          output_path.value(context, output)
        end
      end
    end
  end
end
