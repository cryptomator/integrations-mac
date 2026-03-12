# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

The changelog starts with version 1.4.1.
Changes to prior versions can be found on the [Github release page](https://github.com/cryptomator/integrations-mac/releases).


## [1.5.0](https://github.com/cryptomator/integrations-mac/releases/1.5.0)

### Added
+ DMG Update Mechanism ([#92](https://github.com/cryptomator/integrations-mac/pull/92))

### Changed
* Require JDK 25
* Pin GitHub action versions used in CI ([#97](https://github.com/cryptomator/integrations-mac/pull/97))

### Fixed
* OpenCmdRevealPathService opened two Finder windows when path parameter is a directory ([#109](https://github.com/cryptomator/integrations-mac/pull/109))


## [1.4.1](https://github.com/cryptomator/integrations-mac/releases/tag/1.4.1) - 2025-09-18
### Added
* Added translation for Ukrainian (uk). (#81)

### Changed
* Updated `org.cryptomator:integrations-api` from 1.6.0 to 1.7.0

### Fixed
* Guard NSStrings from being nil in native code. (#80)


