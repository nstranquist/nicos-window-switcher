# Nicos Window Switcher

Clean-room MIT window switcher for macOS. Lists **windows**, not apps. Public
APIs only. Default hotkey is **⌃⌥Tab** so it does not steal AltTab's ⌥Tab.

Study ref: `ndev refs search alt-tab` (`alt-tab-macos`, clone lift, not vendored).
Product law: `recipe.nicos-window-switcher`.

## What it does

- Global Carbon hotkey hold/cycle, release to focus
- Icon + title overlay grid
- Type-to-search
- Exception filters (hide named apps / kinds)
- Optional one-shot thumbnails; list + focus work without Screen Recording
- CLI: `list --json` and `focus --id` (`--dry-run` safe)

## Quick start

```sh
make test
make verify
# optional:
make install   # /Applications/Nicos Window Switcher.app — does not enable launch-at-login
```

```sh
ndev windows list --json
ndev windows focus --id 'PID:WID' --dry-run
.build/app/Nicos\ Window\ Switcher.app/Contents/MacOS/WindowSwitcher toggle
```

## Toggle on / off

The app does not launch at login. Use either surface:

```sh
ndev products enable nicos-window-switcher
ndev products run nicos-window-switcher     # starts (refuses unless enabled)
ndev products stop nicos-window-switcher    # quits the process
ndev products disable nicos-window-switcher # opt out
```

Or the menu-bar **WS** item: **Hotkeys** checks/unchecks ⌃⌥Tab without quitting.
`WindowSwitcher toggle` flips that same switch on the running app.

## Config

`~/.config/nicos-window-switcher/config.json`

```json
{
  "hotkey": { "modifiers": ["control", "option"], "key": "tab" },
  "exceptions": [],
  "thumbnailsEnabled": false
}
```

Nothing autostarts. `ndev products enable nicos-window-switcher` is the opt-in.

## License

MIT. Not a fork of AltTab (GPL-3.0).
