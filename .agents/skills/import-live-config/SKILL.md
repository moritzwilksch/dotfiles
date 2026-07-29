---
name: import-live-config
description: Import changes made to live config files in $HOME back into this chezmoi source repo. Use when asked to "pull in", "import", "sync back", or "re-add" live settings (fish, tmux, Claude Code, VS Code, Zed, nvim, ghostty, lazygit, ...) that were edited outside the repo.
---

# Import live config back into chezmoi

Edits made directly to `~/…` are invisible to this repo until imported. This skill covers
finding what drifted, deciding plain-file vs. template, and doing the import safely.

## 0. Sanitize — non-negotiable

This repo is **public**. The only personal data allowed in is **file paths on Moritz's
machine** (and even those prefer `{{ .chezmoi.homeDir }}`).

Everything else is off-limits and must be stripped, not committed:

- Names of people, teams, usernames, email addresses
- Company or project names; internal hostnames, URLs, repo slugs
- Tokens, keys, cookies, session IDs, account/profile IDs, ARNs
- MCP server endpoints and anything pointing at internal infrastructure

Read every hunk you are about to stage. If a value is identifying, drop the setting
and tell Moritz what you removed. If you are unsure whether a string is sensitive, ask before importing it.

## 1. Find the drift

The source dir is `home/` (set by `.chezmoiroot`), so source paths look like
`home/dot_config/fish/config.fish.tmpl` → `~/.config/fish/config.fish`.

```bash
chezmoi status          # M = live file differs from source, A = live-only
chezmoi diff            # full diff: source (rendered) -> live. Reversed vs. what you want!
chezmoi diff ~/.config/fish/config.fish
```

`chezmoi diff` shows what `apply` *would do to the live file*. Importing means going the
other way, so read it inverted: lines it wants to remove are Moritz's new lines.

For a file not yet managed, first check whether a sibling already covers it (e.g. VS Code
has two paths, see below) and check `home/.chezmoiignore` before adding.

## 2. Plain file or template?

Default to a **plain file**. Only reach for `.tmpl` when the content must actually differ
per platform or per machine.

Use a template when:
- A path differs by OS (`/opt/homebrew/bin/fish` vs `/usr/bin/fish` → `dot_tmux.conf.tmpl`)
- A block applies to one OS only (`{{ if eq .chezmoi.os "darwin" }}…{{ end }}`)
- An absolute home path appears → `{{ .chezmoi.homeDir }}`, never a hardcoded `/Users/...`

Keep plain when the file is identical everywhere (`dot_config/ghostty/config`,
`dot_config/zed/keymap.json`), or when it is a *variant* selected by other means —
`dot_claude/settings.subscription.json` is a plain alternative file, not a template branch.

Platform exclusion is `.chezmoiignore`'s job, not a template's: if a whole file is
macOS-only, list it there rather than wrapping the entire body in an `if`.

Prefer adding an OS branch inside an existing `.tmpl` over introducing a second file.

## 3. Import

**Plain, already-managed file** — safe and mechanical:

```bash
chezmoi re-add ~/.config/ghostty/config     # or bare `chezmoi re-add` for everything
```

**Templated file** — `re-add` deliberately refuses to touch templates. Do it by hand:

```bash
chezmoi execute-template --file home/dot_config/fish/config.fish.tmpl > /tmp/rendered
diff /tmp/rendered ~/.config/fish/config.fish
```

Then Edit the `.tmpl`, placing each new line inside the correct OS branch (or outside all
branches if it is universal). Never paste rendered output over a template — that destroys
the platform logic.

**New file:**

```bash
chezmoi add ~/.config/foo/bar.toml              # plain
chezmoi add --template ~/.config/foo/bar.toml   # template (then generalize the paths)
```

## 4. Repo-specific traps

- **VS Code lives in two directories** and they must stay byte-identical. Apply every
  import to *both*: `home/Library/Application Support/Code/User/` and
  `home/dot_config/Code/User/`. `re-add` only fixes the one for the current OS.
- **`reference/` is not deployed** (Zed configs, mac shortcuts) — it is a manual copy, so
  `chezmoi status` never reports it. Update those files by hand.
- **`home/.chezmoi.toml.tmpl`** is chezmoi's own config; don't import machine state into it.
- **`lazy-lock.json`** is in `.chezmoiignore` — do not import nvim plugin lockfiles.
- Package changes belong in `run_onchange_install-packages.sh.tmpl` *and* its
  `# packages:` comment, not in a config file.
- See `AGENTS.md` for what is currently templated and why before changing that split.

## 5. Verify

```bash
chezmoi diff            # should be empty (or only intended remaining differences)
git diff                # final sanitization read-through — every hunk, every line
```

Report to Moritz: which files were imported, whether any became/stopped being templates,
and anything you dropped for privacy. Don't commit unless asked.
