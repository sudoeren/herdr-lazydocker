# herdr-lazydocker

A [herdr](https://herdr.dev) plugin that brings [lazydocker](https://github.com/jesseduffield/lazydocker) into your terminal workspace. Open it beside your work in a split pane or in its own tab, with a smart toggle: press once to open, again to focus, and again while focused to close. Quitting lazydocker (`q`) closes its pane.

## Features

- **Split pane** (`prefix+m`): lazydocker side by side with your work.

  ![lazydocker in a split pane](docs/split-pane.jpeg)

- **Own tab** (`prefix+shift+m`): full-window lazydocker.

  ![lazydocker in its own tab](docs/tab.png)

- **Smart toggle**: open, focus, or close with repeated presses.
- **Workspace aware**: the tab toggle switches to an existing lazydocker tab in the same workspace instead of spawning duplicates.

## Requirements

- herdr >= 0.7.0
- [lazydocker](https://github.com/jesseduffield/lazydocker) on your `PATH`
- `jq` (optional; without it the shortcuts still work, they just lose the toggle behavior)

## Installation

From GitHub:

```bash
herdr plugin install sudoeren/herdr-lazydocker
herdr plugin list
```

For local development:

```bash
herdr plugin link /path/to/herdr-lazydocker
```

## Keybindings

Add to `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+shift+m"
type = "shell"
command = "herdr plugin action invoke open-lazydocker-tab --plugin herdr-lazydocker"

[[keys.command]]
key = "prefix+m"
type = "shell"
command = "herdr plugin action invoke open-lazydocker --plugin herdr-lazydocker"
```

Reload the config:

```bash
herdr server reload-config
```

## Invoke without keybindings

```bash
herdr plugin action invoke open-lazydocker --plugin herdr-lazydocker
herdr plugin action invoke open-lazydocker-tab --plugin herdr-lazydocker
```

## License

[MIT](LICENSE)
