# ManageIQ::Floe

[![CI](https://github.com/ManageIQ/manageiq-floe/actions/workflows/ci.yaml/badge.svg)](https://github.com/ManageIQ/manageiq-floe/actions/workflows/ci.yaml)

## Overview

Floe is a runner for [Amazon States Language](https://states-language.net/) workflows with support for Docker resources and running on Docker, Podman, or Kubernetes.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add manageiq-floe

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install manageiq-floe

## Usage

Floe can be run as a command-line utility or as a ruby class.

### Command Line

```
bundle exec ruby exe/manageiq-floe --workflow examples/workflow.json --inputs='{"foo": 1}'
```

### Ruby Library

```ruby
require 'manageiq-floe'

workflow = ManageIQ::Floe::Workflow.load(File.read("workflow.json"))
workflow.run!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/manageiq-floe.
