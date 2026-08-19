# Contributing

This public repository is the source for Nicos Window Switcher. It is a
clean-room MIT app. Do not vendor AltTab or any GPL window-server code.

## Local gate

```sh
make test
make verify
```

`make test` runs the Swift package tests. `make verify` is the publication
gate this tree already documents.

## Rules

- Public APIs only. No SkyLight or private window-server symbols.
- Default hotkey stays **⌃⌥Tab**. Do not steal ⌥Tab.
- List **windows**, not apps.
- Keep Screen Recording optional. List and focus must work without it.
- Do not enable launch-at-login from install.

Open a pull request against `main`. Publication to GitHub remains human-gated.
