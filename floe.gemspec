# frozen_string_literal: true

require_relative "lib/floe/version"

Gem::Specification.new do |spec|
  spec.name = "floe"
  spec.version = Floe::VERSION
  spec.authors = ["ManageIQ Developers"]

  spec.summary = "Simple Workflow Runner."
  spec.description = "Simple Workflow Runner."
  spec.homepage = "https://github.com/ManageIQ/floe"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "awesome_spawn", "~>1.0"
  spec.add_dependency "jsonpath", "~>1.1"
  spec.add_dependency "more_core_extensions"
  spec.add_dependency "optimist", "~>3.0"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
end
