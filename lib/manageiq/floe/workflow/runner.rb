module ManageIQ
  module Floe
    class Workflow
      class Runner
        class << self
          def for_resource(resource)
            raise ArgumentError, "resource cannot be nil" if resource.nil?

            scheme = resource.split("://").first

            case scheme
            when "docker"
              # TODO detect if we should use Docker, Podman, or Kubernetes
              Docker.new
            else
              raise "Invalid resource scheme [#{scheme}]"
            end
          end
        end

        def run!(image, env = {}, secrets = {})
          raise NotImplementedError, "Must be implemented in a subclass"
        end
      end
    end
  end
end
