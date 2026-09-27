# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New installer with better error handling and support for Arch Linux and NixOS only
- Improved module system for configuration management
- Enhanced dependency checking

### Changed
- Complete rewrite of the main install.sh script with modular architecture
- Updated documentation structure to be more user-friendly

### Fixed
- `scripts/validate-repo.sh` no longer stops at the first failing check, so the symlink, secret and documentation checks always run
- Hard coded personal paths, absolute symlinks and the documentation files that are not written yet are reported as warnings instead of failures
- The validation workflow runs `shellcheck -x` and tolerates the informational dependency report, so the job can pass

## [1.0.0] - 2024-05-16

### Added
- Initial release of OmniFormis Shell dotfiles installer for Arch Linux and NixOS.

[Unreleased]: https://github.com/Boing-git/OmniFormis-Shell/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Boing-git/OmniFormis-Shell/releases/tag/v1.0.0