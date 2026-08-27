# herdr-lazydocker

[![CI](https://github.com/sudoeren/herdr-lazydocker/actions/workflows/ci.yml/badge.svg)](https://github.com/sudoeren/herdr-lazydocker/actions/workflows/ci.yml)
[![Version: 0.0.1](https://img.shields.io/badge/version-0.0.1-blue.svg)](https://github.com/sudoeren/herdr-lazydocker/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/sudoeren/herdr-lazydocker/blob/main/LICENSE)
![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-orange)



A [herdr](https://herdr.dev/) plugin that runs [lazydocker](https://github.com/jesseduffield/lazydocker) in a split pane or its own tab, with a smart toggle: press once to open, again to focus, and again while focused to close. Quitting lazydocker (`q`) closes its pane. Inspired by [herdr-lazygit](https://github.com/Crokily/herdr-lazygit); see [Acknowledgements](#acknowledgements).

## Quick start

### Let an AI agent install it

Copy this prompt into an AI coding agent running on the machine where you use herdr:

```
Install and configure herdr-lazydocker from https://github.com/sudoeren/herdr-lazydocker for me. Follow the repository README and work idempotently: check that herdr >= 0.7.0 and the required tools are available; run `herdr plugin install sudoeren/herdr-lazydocker`; use the installed herdr CLI/help to locate my active `config.toml`; back it up; and add the documented `prefix+m` and `prefix+shift+m` plugin-action keybindings only if they are missing. Do not overwrite unrelated settings or create duplicate bindings. If either key already has a different binding, stop and show me the conflict instead of choosing a replacement. Reload the herdr config, verify that the plugin is installed and the config reload succeeds, then report exactly what you changed. Do not use sudo or install system packages.
```

### Install manually

Requires herdr >= 0.7.0 plus `bash`, `jq`, and [lazydocker](https://github.com/jesseduffield/lazydocker) on `PATH`.

```bash
herdr plugin install sudoeren/herdr-lazydocker

# or pin a released version:
herdr plugin install sudoeren/herdr-lazydocker --ref v0.0.1
```

Add the launcher keybindings to your active herdr `config.toml`:

```toml
[[keys.command]]              # lazydocker: open in a split
key = "prefix+m"
type = "plugin_action"
command = "herdr-lazydocker.open-lazydocker"

[[keys.command]]              # lazydocker: open in its own tab
key = "prefix+shift+m"
type = "plugin_action"
command = "herdr-lazydocker.open-lazydocker-tab"
```

Run `herdr server reload-config`. `prefix+m` then behaves as: not open -> open in a split; open but unfocused -> focus; focused -> close.

### Herdr Remote

When attaching with `herdr --remote`, Herdr uses local keybindings by default. In current Herdr releases, that local keybinding profile intentionally omits every `[[keys.command]]` entry, including `type = "plugin_action"`. As a result, the launcher bindings above do not work in the default remote mode, even if the same bindings are also present in the local machine's `config.toml`.

Detach and reattach using the remote server's keybindings instead:

```bash
herdr --remote <host> --remote-keybindings server
```

Add `--session <name>` as usual when attaching to a named session. The keybinding policy is selected when attaching, so `herdr server reload-config` does not change it for an already attached remote client. See the [Herdr remote access documentation](https://herdr.dev/docs/persistence-remote/) for details.

## Daily workflow

Press `prefix+m`. A lazydocker split pane opens next to your current directory. Press it again and the pane closes; the launcher never opens a second copy in the same tab.

Press `prefix+shift+m` for the full-window view. If a lazydocker tab already exists in the current workspace, herdr switches to it instead of spawning a duplicate. Press `prefix+shift+m` again while the lazydocker pane is focused to close it.

Inside lazydocker everything is stock: browse containers, images, volumes, and networks with the mouse or keyboard, and manage them with the built-in bindings. Press `?` inside lazydocker for the full list. Quitting with `q` closes the pane, and herdr reuses the spot for your next pane.

## Keybindings

The plugin adds exactly two herdr-level keybindings. Everything else is stock lazydocker:

| Key | Verb | What it does |
| --- | --- | --- |
| `prefix+m` | **Split** | Toggles lazydocker in a split pane beside the current work |
| `prefix+shift+m` | **Tab** | Toggles lazydocker in its own tab, full window |

Both bindings are idempotent. The split binding only acts on a lazydocker pane in the focused pane's tab, and the tab binding only acts on a lazydocker tab in the same workspace, so a launcher press never yanks you into another workspace.

## Features

- **Split pane** (`prefix+m`): lazydocker side by side with your work.
- **Own tab** (`prefix+shift+m`): full-window lazydocker.
- **Smart toggle**: open, focus, or close with repeated presses.
- **Workspace aware**: the tab toggle switches to an existing lazydocker tab in the same workspace instead of spawning duplicates.
- **Context aware**: lazydocker roots at the focused pane's working directory, not the plugin install directory.

## Requirements

- herdr >= 0.7.0
- [lazydocker](https://github.com/jesseduffield/lazydocker) on `PATH`
- `jq` (optional; without it the shortcuts still open lazydocker, they just lose the toggle behavior)

## How it works

Each action is a small `bash` script that talks to the herdr CLI. The split and tab scripts share the same decision logic:

1. Read the invoking pane's working directory from the context herdr injects on action invoke (falling back to the focused pane's cwd, then `$HOME`).
2. Query `herdr pane list` and decide, in `jq`: `OPEN` when no lazydocker pane is present, `FOCUS` when it exists but is unfocused, `CLOSE` when it is the focused pane.
3. Execute the decision. The tab variant adds `SWITCHTAB` for a lazydocker tab elsewhere in the same workspace.

> **Note (herdr platform behavior):** an action's context always resolves from the pane that currently has **UI focus**, not from a background process. The action opens lazydocker next to the user's focused pane, takes its cwd from that pane, and focuses the new pane. Trigger these actions only through foreground keybindings.

## Local development

```bash
git clone https://github.com/sudoeren/herdr-lazydocker
herdr plugin link /path/to/herdr-lazydocker
```

Link does not run any build step; the plugin has none. Scripts are executed from the checkout, so edits apply on the next action invoke. Reload the config with `herdr server reload-config` after linking or unlinking.

## Layout

```
herdr-plugin.toml            # plugin manifest
LICENSE                      # MIT license
README.md
.github/
  workflows/ci.yml           # CI: hermetic test suite on Linux and macOS
scripts/
  open-lazydocker.sh         # action: open in a split (open / focus / close)
  open-lazydocker-tab.sh     # action: open in a tab (open / switch / close)
tests/
  run-tests.sh               # hermetic suite with a mocked herdr CLI
```

## Acknowledgements

This project is inspired by [herdr-lazygit](https://github.com/Crokily/herdr-lazygit) by [Crokily](https://github.com/Crokily), which applies the same smart split/tab toggle pattern to [lazygit](https://github.com/jesseduffield/lazygit). herdr-lazydocker is an independent adaptation of that idea for [lazydocker](https://github.com/jesseduffield/lazydocker).

## License

[MIT](LICENSE)
