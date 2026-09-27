#!/usr/bin/env bash
# setup-linux.sh — терминал под zsh (WSL Ubuntu / Debian):
# наши конфиги (тема, .zshrc) тянутся из GitHub, стандартный софт — из apt/официальных установщиков.
# Идемпотентен: и на новой, и на текущей машине. История НЕ трогается.
set -uo pipefail

REPO="MikhailVMV/terminal-config"
BRANCH="main"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"

info(){ printf '\033[36m==> %s\033[0m\n' "$1"; }
warn(){ printf '\033[33m!!  %s\033[0m\n' "$1"; }

# --- 1. Пакеты apt ---
info "apt: базовые пакеты"
sudo apt update
sudo apt install -y zsh git curl wget unzip fzf ripgrep fd-find bat

if ! command -v eza >/dev/null 2>&1; then
  info "Ставлю eza"
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo apt update && sudo apt install -y eza || warn "eza не встала из репозитория — поставь вручную"
fi
if ! command -v delta >/dev/null 2>&1; then
  sudo apt install -y git-delta 2>/dev/null || warn "git-delta нет в apt — поставь .deb с github.com/dandavison/delta/releases"
fi
if ! command -v zoxide >/dev/null 2>&1; then
  info "Ставлю zoxide"; curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# --- 2. oh-my-posh ---
info "Устанавливаю/обновляю oh-my-posh"
mkdir -p ~/.local/bin
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
if grep -qi microsoft /proc/version 2>/dev/null; then
  info "WSL: шрифт берётся из Windows Terminal (ставит setup-windows.ps1) — пропускаю"
else
  oh-my-posh font install meslo || warn "шрифт не установился — поставь Nerd Font вручную"
fi

# --- 3. oh-my-zsh ---
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$ZSH" ]; then
  info "Ставлю oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# --- 4. zsh-плагины ---
clone_plugin(){ local d="$ZSH_CUSTOM/plugins/$2"; if [ -d "$d" ]; then git -C "$d" pull --quiet || true; else git clone --quiet "$1" "$d"; fi; }
clone_plugin https://github.com/zsh-users/zsh-autosuggestions      zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting  zsh-syntax-highlighting
clone_plugin https://github.com/zsh-users/zsh-completions          zsh-completions
clone_plugin https://github.com/Aloxaf/fzf-tab                     fzf-tab
clone_plugin https://github.com/MichaelAquilina/zsh-you-should-use you-should-use

# --- 5. Тема (из GitHub) ---
curl -fsSL "$BASE/terminal.omp.json" -o ~/terminal.omp.json
info "Тема: ~/terminal.omp.json"

# --- 6. .zshrc (из GitHub; старый в бэкап) ---
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak && info "Старый .zshrc сохранён: ~/.zshrc.bak"
curl -fsSL "$BASE/zshrc" -o ~/.zshrc

info "Готово. Запусти новый zsh:  exec zsh"
warn "delta установлена, но как git-pager НЕ включена. Включить:"
echo "    git config --global core.pager delta"
echo "    git config --global interactive.diffFilter 'delta --color-only'"
echo "    git config --global delta.navigate true"
