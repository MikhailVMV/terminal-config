# ==== terminal-config: .zshrc (github.com/MikhailVMV/terminal-config) ====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # промпт рисует oh-my-posh

# fzf-tab — после автоподсказок и ПЕРЕД syntax-highlighting (он всегда последний)
plugins=(git zsh-completions zsh-autosuggestions fzf-tab you-should-use zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"

# История (существующий ~/.zsh_history сохраняется)
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY HIST_IGNORE_ALL_DUPS

# Промпт
eval "$(oh-my-posh init zsh --config ~/terminal.omp.json)"

# zoxide — умный cd: "z proxmox"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# fzf: Ctrl+R (история), Ctrl+T (файлы)
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do [ -f "$f" ] && source "$f"; done
    for f in /usr/share/doc/fzf/examples/completion.zsh   /usr/share/fzf/completion.zsh;   do [ -f "$f" ] && source "$f"; done
  fi
fi

# Утилиты под их именами (ls/cat НЕ переопределяем)
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'

# Локальные машинно-специфичные алиасы/настройки (не в репозитории)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
