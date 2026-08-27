# herdr-lazydocker

[![CI](https://github.com/sudoeren/herdr-lazydocker/actions/workflows/ci.yml/badge.svg)](https://github.com/sudoeren/herdr-lazydocker/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/sudoeren/herdr-lazydocker/blob/main/LICENSE)
![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-orange)



A [herdr](https://herdr.dev/) plugin that runs [lazydocker](https://github.com/jesseduffield/lazydocker) in a split pane or its own tab. Quitting lazydocker (`q`) closes its pane. Inspired by [herdr-lazygit](https://github.com/Crokily/herdr-lazygit); see [Acknowledgements](#acknowledgements).

## Quick start

### Let an AI agent install it

Copy this prompt into an AI coding agent running on the machine where you use herdr:

```
Install and configure herdr-lazydocker from https://github.com/sudoeren/herdr-lazydocker idempotently: verify herdr >= 0.7.0 and required tools, run `herdr plugin install sudoeren/herdr-lazydocker`, back up my active `config.toml`, and add the `prefix+m` / `prefix+shift+m` plugin-action bindings only if missing. Don't overwrite unrelated settings or duplicate bindings; if a key is already bound differently, stop and report the conflict. Reload the config and verify. Mention that the shortcuts can be customized later by editing the keys in `config.toml`. No sudo or system packages.
```

### Install manually

Requires herdr >= 0.7.0 plus `bash`, `jq`, and [lazydocker](https://github.com/jesseduffield/lazydocker) on `PATH`.

```bash
herdr plugin install sudoeren/herdr-lazydocker
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

Run `herdr server reload-config`.

### Herdr Remote

When attaching with `herdr --remote`, Herdr uses local keybindings by default. In current Herdr releases, that local keybinding profile intentionally omits every `[[keys.command]]` entry, including `type = "plugin_action"`. As a result, the launcher bindings above do not work in the default remote mode, even if the same bindings are also present in the local machine's `config.toml`.

Detach and reattach using the remote server's keybindings instead:

```bash
herdr --remote <host> --remote-keybindings server
```

Add `--session <name>` as usual when attaching to a named session. The keybinding policy is selected when attaching, so `herdr server reload-config` does not change it for an already attached remote client. See the [Herdr remote access documentation](https://herdr.dev/docs/persistence-remote/) for details.

## Daily workflow

Press `prefix+m`. A lazydocker split pane opens next to your current directory.

Press `prefix+shift+m` for the full-window view.

Inside lazydocker everything is stock: browse containers, images, volumes, and networks with the mouse or keyboard, and manage them with the built-in bindings. Press `?` inside lazydocker for the full list. Quitting with `q` closes the pane, and herdr reuses the spot for your next pane.

## Keybindings

The plugin adds exactly two herdr-level keybindings. Everything else is stock lazydocker:

| Key | Verb | What it does |
| --- | --- | --- |
| `prefix+m` | **Split** | Opens lazydocker in a split pane beside the current work |
| `prefix+shift+m` | **Tab** | Opens lazydocker in its own tab, full window |

The split binding only acts on the focused pane's tab, and the tab binding only acts within the same workspace.

### Customizing the shortcuts

The bindings are plain herdr `[[keys.command]]` entries in your `config.toml`, so you can change or remove them freely:

- **Change a key**: edit the `key` value in the matching block and run `herdr server reload-config`.
- **Remove a binding**: delete the whole `[[keys.command]]` block (keys starting with `[[keys.command]]` are standalone entries, not inside a list).
- **Keep the defaults**: the install steps above already add them; just leave `config.toml` alone.

The actions themselves (`herdr-lazydocker.open-lazydocker`, `herdr-lazydocker.open-lazydocker-tab`) come from the plugin and are not meant to be renamed — only the keys that trigger them are user-configurable.

## Features

- **Split pane** (`prefix+m`): lazydocker side by side with your work.
- **Own tab** (`prefix+shift+m`): full-window lazydocker.
- **Workspace aware**: the tab action switches to an existing lazydocker tab in the same workspace instead of spawning duplicates.
- **Context aware**: lazydocker roots at the focused pane's working directory, not the plugin install directory.

## Requirements

- herdr >= 0.7.0
- [lazydocker](https://github.com/jesseduffield/lazydocker) on `PATH`
- `jq` (optional; without it the shortcuts still open lazydocker)

## How it works

Each action is a small `bash` script that talks to the herdr CLI. The split and tab scripts share the same decision logic:

1. Read the invoking pane's working directory from the context herdr injects on action invoke (falling back to the focused pane's cwd, then `$HOME`).
2. Open lazydocker with `herdr plugin pane open` in the requested placement, rooted at that directory.

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
  open-lazydocker.sh         # action: open in a split
  open-lazydocker-tab.sh     # action: open in a tab
tests/
  run-tests.sh               # hermetic suite with a mocked herdr CLI
```

## Acknowledgements

This project is inspired by [herdr-lazygit](https://github.com/Crokily/herdr-lazygit) by [Crokily](https://github.com/Crokily), which opens [lazygit](https://github.com/jesseduffield/lazygit) in a herdr split or tab. herdr-lazydocker is an independent adaptation of that idea for [lazydocker](https://github.com/jesseduffield/lazydocker).

## License

[MIT](LICENSE)
