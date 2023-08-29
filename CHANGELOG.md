# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.3.1] - 2023-08-29
### Added
- Add more global podman runner options ([#90])(https://github.com/ManageIQ/floe/pull/90)

## [0.3.0] - 2023-08-07
### Added
- Add --network=host option to Docker/Podman runners ([#81])(https://github.com/ManageIQ/floe/pull/81)

### Fixed
- Fix PayloadTemplate value transformation rules ([#78])(https://github.com/ManageIQ/floe/pull/78)
- Move end out of the root state node ([#80])(https://github.com/ManageIQ/floe/pull/80)

## [0.2.3] - 2023-07-28
### Fixed
- Fix storing next_state in Context ([#76])(https://github.com/ManageIQ/floe/pull/76)

## [0.2.2] - 2023-07-24
### Fixed
- Don't pick up real KUBECONFIG for tests ([#73](https://github.com/ManageIQ/floe/pull/73))
- Fix double json.parse and context default value ([#69](https://github.com/ManageIQ/floe/pull/69))

### Added
- Configure Renovate ([#46](https://github.com/ManageIQ/floe/pull/46))

### Changed
- Simplify next state handling ([#66](https://github.com/ManageIQ/floe/pull/66))
- Refactor Input/Output path handling ([#68](https://github.com/ManageIQ/floe/pull/68))

## [0.2.1] - 2023-07-12
### Fixed
- Fix State EnteredTime and FinishedTime ([#59](https://github.com/ManageIQ/floe/pull/59))

### Added
- Add workflow output ([#57](https://github.com/ManageIQ/floe/pull/57))

## [0.2.0] - 2023-07-05
### Added
- Add ability to pass options to `Floe::Workflow::Runner` ([#48](https://github.com/ManageIQ/floe/pull/48))
- Add kubeconfig file support to `Floe::Workflow::Runner::Kubernetes` ([#53](https://github.com/ManageIQ/floe/pull/53))

### Removed
- Remove to_dot/to_svg code ([#54](https://github.com/ManageIQ/floe/pull/54))

### Fixed
- Fixed default rake task to spec ([#55](https://github.com/ManageIQ/floe/pull/55))

## [0.1.1] - 2023-06-05
### Fixed
- Fix States::Wait Path initializer arguments ([#47](https://github.com/ManageIQ/floe/pull/47))

## [0.1.0] - 2023-03-13
### Added
- Initial release

[Unreleased]: https://github.com/ManageIQ/floe/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/ManageIQ/floe/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/ManageIQ/floe/compare/v0.2.3...v0.3.0
[0.2.3]: https://github.com/ManageIQ/floe/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/ManageIQ/floe/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/ManageIQ/floe/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ManageIQ/floe/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/ManageIQ/floe/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ManageIQ/floe/tree/v0.1.0
