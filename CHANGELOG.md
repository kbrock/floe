# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.2.2] - 2023-07-24
### Fixed
- Don't pick up real KUBECONFIG for tests (#73)
- Fix double json.parse and context default value (#69)

### Added
- Configure Renovate (#46)

### Changed
- Simplify next state handling (#66)
- Refactor Input/Output path handling (#68)

## [0.2.1] - 2023-07-12
### Fixed
- Fix State EnteredTime and FinishedTime (#59)

### Added
- Add workflow output (#57)

## [0.2.0] - 2023-07-05
### Added
- Add ability to pass options to `Floe::Workflow::Runner` (#48)
- Add kubeconfig file support to `Floe::Workflow::Runner::Kubernetes` (#53)

### Removed
- Remove to_dot/to_svg code (#54)

### Fixed
- Fixed default rake task to spec (#55)

## [0.1.1] - 2023-06-05
### Fixed
- Fix States::Wait Path initializer arguments (#47)

## [0.1.0] - 2023-03-13
### Added
- Initial release

[Unreleased]: https://github.com/ManageIQ/floe/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/ManageIQ/floe/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/ManageIQ/floe/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ManageIQ/floe/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/ManageIQ/floe/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ManageIQ/floe/tree/v0.1.0
