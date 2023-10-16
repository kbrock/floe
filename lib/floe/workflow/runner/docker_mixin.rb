module Floe
  class Workflow
    class Runner
      module DockerMixin
        def image_name(image)
          image.match(%r{^(?<repository>.+/)?(?<image>.+):(?<tag>.+)$})&.named_captures&.dig("image")
        end

        def container_name(image)
          name = image_name(image)
          raise ArgumentError, "Invalid docker image [#{image}]" if name.nil?

          "floe-#{name}-#{SecureRandom.uuid}"
        end
      end
    end
  end
end
