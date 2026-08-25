# herdr-lazydocker

Open [lazydocker](https://github.com/jesseduffield/lazydocker) in a herdr split pane or its own tab, with smart toggle: press once to open, again to focus, and again (while focused) to close. Quitting lazydocker (`q`) closes the pane.

**Split pane** (`prefix+m`) — lazydocker beside your work:

![lazydocker in a herdr split pane](docs/split-pane.jpeg)

**Own tab** (`prefix+d`) — full-window lazydocker:

![lazydocker in its own herdr tab](docs/tab.png)

Requires herdr ≥ 0.7.0, `lazydocker`, and `jq` (without jq the shortcut still opens lazydocker, it just loses the toggle).

## Install

```bash
herdr plugin install <you>/herdr-lazydocker
herdr plugin list   # confirm herdr-lazydocker is registered
```

For local development:

```bash
herdr plugin link /path/to/herdr-lazydocker
```

## Keybindings

Add to `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+d"
type = "shell"
command = "herdr plugin action invoke open-lazydocker-tab --plugin herdr-lazydocker"

[[keys.command]]
key = "prefix+m"
type = "shell"
command = "herdr plugin action invoke open-lazydocker --plugin herdr-lazydocker"
```

> **Why `prefix+m` for the split?** `prefix+d` was the obvious choice for both,
> and `prefix+shift+d` would have been the natural split sibling — but herdr
> already reserves `prefix+shift+d` for `close_workspace`. `prefix+m` and
> `prefix+d` are both free in the default keymap. Pick keys that fit your
> setup; see the herdr keybindings reference (`prefix+?` in herdr) for what is
> free.

Then reload:

```bash
herdr server reload-config
```

Or invoke without a keybinding:

```bash
herdr plugin action invoke open-lazydocker --plugin herdr-lazydocker
herdr plugin action invoke open-lazydocker-tab --plugin herdr-lazydocker
```
