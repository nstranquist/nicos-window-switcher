# Changelog

All notable changes to Nicos Window Switcher are recorded here. This project
follows [Semantic Versioning](https://semver.org/).

## Unreleased

## [0.1.0] — 2026-11-02

First public source release. This release does not include a downloadable
notarized application; build from source with `make verify` or `make install`.

### Added

- Clean-room MIT window switcher for macOS 14+ that lists **windows**, not
  apps, using public Accessibility, Carbon hotkey, and CoreGraphics APIs only.
- Global Carbon hotkey (default **⌃⌥Tab**, so AltTab's ⌥Tab stays free):
  hold to show, press again to cycle, release to focus.
- Icon + title overlay grid with type-to-search ranking.
- Exception filters that hide named apps or window kinds.
- Optional one-shot ScreenCaptureKit thumbnails. List and focus work without
  Screen Recording.
- Catalog labels for live scratchpad and NDev Pressure windows.
- Empty-title focus matching by window bounds for same-PID windows.
- Menu-bar **WS** item with a **Hotkeys** toggle, plus `WindowSwitcher toggle`
  to flip the same switch on the running app.
- Single-instance lock and an Accessibility permission prompt.
- CLI: `list --json` and `focus --id PID:WID` with a safe `--dry-run`.
- Config at `~/.config/nicos-window-switcher/config.json` (hotkey,
  exceptions, thumbnails). Nothing autostarts; install does not enable
  launch at login.
- `make test`, `make verify` (unit tests, ad-hoc-signed app bundle, headless
  self-test smoke, signature and bundle checks), and GitHub Actions CI.
- README, LICENSE (MIT), PRIVACY, SECURITY, and CONTRIBUTING.

[0.1.0]: https://github.com/nstranquist/nicos-window-switcher/releases/tag/v0.1.0
