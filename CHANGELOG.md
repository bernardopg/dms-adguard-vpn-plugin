# Changelog

## [1.1.0] - 2026-02-26

### Added

- Multilingual UI support with translation bundles (`en_US` and `pt_BR`)
- Translation contribution guide for community localization
- Plugin screenshot assets for registry publishing

### Fixed

- DMS plugin enable failure caused by `AdGuardVpnI18n.qml` invalid `Connections` placement
- Widget focus handling race for DNS input updates during typing
- QML warning path caused by unstable `Ref` usage in widget/service wiring

### Changed

- Updated repository URL examples in installation documentation
- Refined README visuals and publishing readiness for registry submission

## [1.0.0] - 2026-02-26

### Added

- Initial AdGuard VPN widget plugin for DankMaterialShell
- Live monitoring for status, config, license and locations
- Actions: connect/disconnect/fastest/location connect
- Runtime config controls for mode, protocol, channel and DNS
- Settings screen with polling and strategy controls
- Technical docs: architecture and command mapping
