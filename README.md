# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Supports macOS (primary), Linux (servers), and Windows (WezTerm only).

## Install (new machine)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply moritzwilksch
```

This single command installs chezmoi, clones this repo, and applies all configs. On first run, chezmoi also:

- Installs system packages (Homebrew on macOS, apt/dnf/... on Linux)
- Installs [pixi](https://pixi.sh) and syncs global tool environments

## Update (existing machine)

Pull the latest changes and re-apply:

```bash
chezmoi update
```

## Edit configs

Edit the source files, then apply:

```bash
chezmoi edit ~/.config/fish/config.fish
chezmoi apply
```

Or edit directly in this repo and run `chezmoi apply`.

## How it works

- `home/` is the chezmoi source directory (set via `.chezmoiroot`)
- Files prefixed with `dot_` map to dotfiles (e.g. `dot_zshrc` -> `~/.zshrc`)
- `.tmpl` files are Go templates, used for OS-specific sections (shell paths, aliases, PATH)
- `.chezmoiignore` excludes files per OS (e.g. WezTerm only on Windows, `Library/` only on macOS)
- `run_once_*` scripts run once per machine (pixi install)
- `run_onchange_*` scripts re-run when their content changes (package installs, pixi global sync)

## What's included

| Config | macOS | Linux | Windows |
|--------|-------|-------|---------|
| fish shell | x | x | |
| tmux | x | x | |
| ghostty | x | x | |
| VS Code | x | x | |
| WezTerm | | | x |
| pixi globals | x | x | |
| zshrc | x | x | |

## Reference files

`reference/` contains Zed editor configs that are not auto-deployed. Copy manually as needed.
