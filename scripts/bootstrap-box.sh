#!/usr/bin/env bash
# Robust bootstrap for common AWS Linux distros (Ubuntu/Debian, Amazon Linux, RHEL/Rocky/Alma, SUSE, Alpine)
# Installs core tools, Neovim (pkg-manager when possible, x86_64 tarball fallback), fish config, pixi, dotfiles.

set -u  # (no -e so we don't crash on individual failures)
cd "$HOME" || exit 0

log()  { printf "\033[1;34m[BOOTSTRAP]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR]\033[0m %s\n" "$*"; }

# Detect sudo
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# If not root and no sudo, we can only do user-space steps
if [ "$(id -u)" -ne 0 ] && [ -z "${SUDO}" ]; then
  warn "No sudo and not running as root. System package installs will be skipped."
fi

# Detect package manager
PKG_MGR=""
if command -v apt-get >/dev/null 2>&1; then
  PKG_MGR="apt"
elif command -v dnf >/dev/null 2>&1; then
  PKG_MGR="dnf"
elif command -v yum >/dev/null 2>&1; then
  PKG_MGR="yum"
elif command -v zypper >/dev/null 2>&1; then
  PKG_MGR="zypper"
elif command -v apk >/dev/null 2>&1; then
  PKG_MGR="apk"
fi
log "Detected package manager: ${PKG_MGR:-none}"

# Helpers
pkg_update() {
  case "$PKG_MGR" in
    apt)   [ -n "$SUDO" ] && $SUDO apt-get update -y || apt-get update -y ;;
    dnf)   [ -n "$SUDO" ] && $SUDO dnf -y makecache || dnf -y makecache ;;
    yum)   [ -n "$SUDO" ] && $SUDO yum -y makecache fast || yum -y makecache fast ;;
    zypper)[ -n "$SUDO" ] && $SUDO zypper -n refresh || zypper -n refresh ;;
    apk)   [ -n "$SUDO" ] && $SUDO apk update || apk update ;;
    *)     warn "No package manager update step." ;;
  esac
}

pkg_install_many() {
  # install list of pkgs, continue on individual failures
  for p in "$@"; do
    case "$PKG_MGR" in
      apt)    ([ -n "$SUDO" ] && $SUDO apt-get install -y "$p" || apt-get install -y "$p") >/dev/null 2>&1 || warn "apt failed for $p" ;;
      dnf)    ([ -n "$SUDO" ] && $SUDO dnf install -y "$p" || dnf install -y "$p") >/dev/null 2>&1 || warn "dnf failed for $p" ;;
      yum)    ([ -n "$SUDO" ] && $SUDO yum install -y "$p" || yum install -y "$p") >/dev/null 2>&1 || warn "yum failed for $p" ;;
      zypper) ([ -n "$SUDO" ] && $SUDO zypper -n install --no-recommends "$p" || zypper -n install --no-recommends "$p") >/dev/null 2>&1 || warn "zypper failed for $p" ;;
      apk)    ([ -n "$SUDO" ] && $SUDO apk add --no-cache "$p" || apk add --no-cache "$p") >/dev/null 2>&1 || warn "apk failed for $p" ;;
      *)      warn "No pkg manager to install $p" ;;
    esac
  done
}

maybe_enable_extras() {
  # Enable common repos on RPM systems to unlock packages like ripgrep/fzf/neovim
  case "$PKG_MGR" in
    dnf|yum)
      if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        # EPEL for RHEL/Rocky/Alma; harmless/no-op on some Amazon images
        pkg_install_many epel-release
        # Amazon Linux 2 extras (may fail harmlessly elsewhere)
        command -v amazon-linux-extras >/dev/null 2>&1 && ($SUDO amazon-linux-extras enable epel 2>/dev/null || true)
      fi
      ;;
  esac
}

# Base packages (names are best-effort across distros)
BASE_PKGS_COMMON="git htop zsh wget curl make tmux gcc"
BASE_PKGS_NICE="fish ripgrep fzf"
BASE_PKGS_DEBIAN_EXTRA="software-properties-common"
BASE_PKGS_ALPINE_EXTRA="build-base"

install_base_packages() {
  [ -z "$PKG_MGR" ] && { warn "Skipping base installs: no package manager detected."; return; }
  maybe_enable_extras
  pkg_update

  case "$PKG_MGR" in
    apt)
      # PPA for fish latest (optional; skip errors)
      if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        ($SUDO apt-get install -y ${BASE_PKGS_DEBIAN_EXTRA} >/dev/null 2>&1 && \
         $SUDO apt-add-repository -y ppa:fish-shell/release-3 >/dev/null 2>&1) || warn "Fish PPA not added; using repo versions."
        pkg_update
      fi
      ;;
  esac

  pkg_install_many $BASE_PKGS_COMMON $BASE_PKGS_NICE

  # Alpine build tools alias
  [ "$PKG_MGR" = "apk" ] && pkg_install_many $BASE_PKGS_ALPINE_EXTRA
}

install_neovim() {
  log "Installing Neovim (prefer package manager)..."
  # 1) Try package manager
  case "$PKG_MGR" in
    apt)    pkg_install_many neovim ;;
    dnf)    pkg_install_many neovim ;;
    yum)    pkg_install_many neovim ;;
    zypper) pkg_install_many neovim ;;
    apk)    pkg_install_many neovim ;;
  esac

  if command -v nvim >/dev/null 2>&1; then
    log "Neovim installed via package manager."
    return 0
  fi

  # 2) Fallback to upstream tarball for x86_64 only
  ARCH="$(uname -m || echo unknown)"
  if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    TMP_DIR="$(mktemp -d)"
    cd "$TMP_DIR" || return 0
    log "Downloading Neovim x86_64 tarball..."
    if curl -fsSLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz; then
      tar -xzf nvim-linux64.tar.gz
      # install to /usr/local and symlink
      if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        $SUDO rm -rf /usr/local/nvim 2>/dev/null || true
        $SUDO mv nvim-linux64 /usr/local/nvim
        [ -d /usr/local/bin ] || ($SUDO mkdir -p /usr/local/bin)
        $SUDO ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim
        log "Neovim installed to /usr/local/nvim and symlinked to /usr/local/bin/nvim."
      else
        mkdir -p "$HOME/.local/opt"
        mv nvim-linux64 "$HOME/.local/opt/nvim"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
        case ":$PATH:" in
          *":$HOME/.local/bin:"*) : ;;
          *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
        esac
        log "Neovim installed in user-space at ~/.local/opt/nvim."
      fi
    else
      warn "Failed to download Neovim tarball."
    fi
    cd "$HOME" || true
    rm -rf "$TMP_DIR" || true
  else
    warn "Neovim tarball fallback is only for x86_64; skipping (arch: $ARCH)."
  fi

  if ! command -v nvim >/dev/null 2>&1; then
    warn "Neovim not available. You can install later or use vim/nano temporarily."
  fi
}

# Clone Neovim config (idempotent)
install_nvim_config() {
  mkdir -p "$HOME/.config"
  if [ -d "$HOME/.config/nvim/.git" ]; then
    log "Updating existing nvim config..."
    (cd "$HOME/.config/nvim" && git pull --ff-only >/dev/null 2>&1) || warn "Failed to update nvim config."
  else
    log "Cloning nvim config..."
    (cd "$HOME/.config" && git clone https://github.com/moritzwilksch/nvim.git >/dev/null 2>&1) || warn "Failed to clone nvim config."
  fi
}

# Dotfiles (idempotent)
install_dotfiles() {
  log "Downloading dotfiles..."
  mkdir -p "$HOME/.config/fish"
  curl -fsSL -o "$HOME/.tmux.conf" https://raw.githubusercontent.com/moritzwilksch/dotfiles/main/.tmux.conf || warn ".tmux.conf download failed."
  curl -fsSL -o "$HOME/.config/fish/config.fish" https://github.com/moritzwilksch/dotfiles/raw/main/.config/fish/config.fish || warn "fish config download failed."
}

# Append a line to a file only if it isn't already present
append_unique() {
  local line="$1"
  local file="$2"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Pixi
install_pixi() {
  log "Installing pixi..."
  # Installer goes to ~/.pixi and updates PATH automatically in its shell snippet
  curl -fsSL https://pixi.sh/install.sh | bash || warn "Pixi install failed."
  mkdir -p "$HOME/.config/fish"
  append_unique 'pixi completion --shell fish | source' "$HOME/.config/fish/config.fish"
  # Ensure global manifest and update
  mkdir -p "$HOME/.pixi/manifests"
  if curl -fsSL -o "$HOME/.pixi/manifests/pixi-global.toml" \
    https://raw.githubusercontent.com/moritzwilksch/dotfiles/main/.pixi/manifests/pixi-global.toml; then
    if [ -x "$HOME/.pixi/bin/pixi" ]; then
      "$HOME/.pixi/bin/pixi" global update || warn "pixi global update failed."
    else
      pixi global update || warn "pixi global update failed."
    fi
  else
    warn "Failed to download pixi-global.toml."
  fi
}

# Aliases (idempotent)
install_aliases() {
  log "Defining aliases..."
  mkdir -p "$HOME/.config/fish"
  CFG="$HOME/.config/fish/config.fish"
  touch "$CFG"
  append_unique "alias ll='ls -al'" "$CFG"
  append_unique "alias la='ls -al'" "$CFG"
  append_unique "alias mm='micromamba'" "$CFG"
  append_unique "alias ipy='ipython'" "$CFG"
  append_unique "alias ipyi='ipython -i'" "$CFG"

  # Point to whichever nvim is first on PATH, with a stable alias
  if command -v nvim >/dev/null 2>&1; then
    NVIM_PATH="$(command -v nvim)"
    append_unique "alias nvim=${NVIM_PATH}" "$CFG"
  else
    warn "nvim not found for alias; skipping."
  fi
}

# Optional: change login shell to fish (commented to avoid surprising changes)
# change_shell_to_fish() {
#   if command -v fish >/dev/null 2>&1; then
#     TARGET="$(command -v fish)"
#     if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
#       chsh -s "$TARGET" "$USER" || warn "Could not change default shell."
#     else
#       warn "Not root and no sudo; cannot change login shell."
#     fi
#   fi
# }

# --- Execute steps ---
install_base_packages
install_neovim
install_nvim_config
install_dotfiles
install_pixi
install_aliases
# change_shell_to_fish

log "Bootstrap complete."
