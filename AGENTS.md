# Agents Guide

Chezmoi-managed dotfiles. Public repo — no secrets/employer info.
For chezmoi concepts (naming conventions, templates, run scripts), see https://www.chezmoi.io/reference/.

## Platforms

- **macOS** (primary) — Homebrew, fish, Ghostty, VS Code, Claude Code
- **Linux** (servers) — apt/dnf/yum/zypper/apk, fish, VS Code, tmux
- **Windows** — WezTerm only, everything else excluded via `.chezmoiignore`

## Chezmoi naming conventions

- Files prefixed with `dot_` map to dotfiles (e.g. `dot_zshrc` → `~/.zshrc`)
- `.tmpl` files are Go templates, used for OS-specific sections
- `.chezmoiignore` excludes files per OS (e.g. WezTerm only on Windows, `Library/` only on macOS)
- `run_once_*` scripts run once per machine
- `run_onchange_*` scripts re-run when their rendered content changes

## Repo-specific structure

- `.chezmoiroot` is set to `home` — the chezmoi source dir is `home/`, not the repo root
- `reference/` contains Zed editor configs that are **not deployed** (manual copy only)

## What's templated and why

- **tmux**: shell path — `/opt/homebrew/bin/fish` (macOS) vs `/usr/bin/fish` (Linux)
- **fish config**: Homebrew PATH, `claude-aws` alias, OrbStack init are macOS-only
- **claude settings**: `AWS_CONFIG_FILE` uses `{{ .chezmoi.homeDir }}` for portability
- **run scripts**: all skip on Windows

## VS Code: two paths, one config

VS Code settings live at different paths per OS. Both directories contain **identical files** and must be kept in sync:
- macOS: `home/Library/Application Support/Code/User/`
- Linux: `home/dot_config/Code/User/`

## Run script triggers

- `run_onchange_install-packages.sh.tmpl` — triggered by a `# packages: ...` comment at the top. **Update that comment** when adding/removing packages.
- `run_onchange_pixi-global-sync.sh.tmpl` — embeds `{{ include "dot_config/pixi/manifests/pixi-global.toml" | sha256sum }}`, so it re-runs when the pixi manifest changes.

## How to add a package

- **Homebrew**: add to the `brew install` line AND the `# packages:` comment in `run_onchange_install-packages.sh.tmpl`
- **Linux**: add to the `pkg_install` call AND the `# packages:` comment in the same script
- **pixi global tool**: add `[envs.toolname]` to `home/dot_config/pixi/manifests/pixi-global.toml`

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

## Re-running install scripts

The normal path is `chezmoi apply` — `run_onchange_*` scripts re-run when their rendered content changes.

To manually render and execute the package install script:
```bash
chezmoi execute-template --file home/run_onchange_install-packages.sh.tmpl | bash
```

To force chezmoi to consider a script "not yet run", delete its `scriptState` entry:
```bash
hash="$(chezmoi state get --bucket=entryState --key="$HOME/install-packages.sh" | jq -r '.contentsSHA256')"
chezmoi state delete --bucket=scriptState --key="$hash"
chezmoi apply
```
