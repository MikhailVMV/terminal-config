# terminal-config

Единое окружение терминала (PowerShell 7 + CMD/Clink + WSL zsh) с темой Oh My Posh.
Наши конфиги хранятся здесь, стандартный софт ставится из оригинальных источников (winget / apt / официальные установщики). Разворачивается с нуля одной командой.

## Что ставится

**Тема:** `terminal.omp.json` (Oh My Posh) — одинаковая во всех трёх оболочках.

**Windows (PowerShell 7):** Oh My Posh, Clink, zoxide, eza, bat, fd, ripgrep, delta, fzf, git;
модули PSReadLine (история/предсказания/подсветка), PSFzf, Terminal-Icons, CompletionPredictor, posh-git (тяжёлые — с отложенной загрузкой). Meslo Nerd Font + прописывание в Windows Terminal. Исключение Defender для процесса Oh My Posh (быстрый старт).

**CMD (Clink):** Oh My Posh, zoxide, clink-completions, clink-fzf.

**WSL / Linux (zsh):** Oh My Posh, oh-my-zsh + zsh-completions, zsh-autosuggestions, fzf-tab, you-should-use, zsh-syntax-highlighting; zoxide, eza, bat, fd, ripgrep, delta, fzf.

## Установка на новом ПК

Требуется Windows 11 (winget) и, для WSL-части, установленный WSL с Ubuntu.

### Windows (PowerShell 7)
```powershell
irm https://raw.githubusercontent.com/MikhailVMV/terminal-config/main/setup-windows.ps1 -OutFile "$env:TEMP\setup-windows.ps1"; pwsh -ExecutionPolicy Bypass -File "$env:TEMP\setup-windows.ps1"
```
Скрипт запросит UAC (нужно для Defender и шрифта). После — перезапустить PowerShell и CMD.

### WSL / Linux (в оболочке WSL)
```bash
curl -fsSL https://raw.githubusercontent.com/MikhailVMV/terminal-config/main/setup-linux.sh | bash
```
После — `exec zsh`.

## Обновление конфигурации

1. Правишь файл (`terminal.omp.json`, `Microsoft.PowerShell_profile.ps1` или `zshrc`) и пушишь в репозиторий.
2. На других машинах — повторно запускаешь ту же команду установки (скрипт идемпотентен: пере-качает конфиги, пакеты не трогает, если уже стоят).

Быстро обновить только тему, без переустановки:
```powershell
irm https://raw.githubusercontent.com/MikhailVMV/terminal-config/main/terminal.omp.json -OutFile "$HOME\terminal.omp.json"
```
```bash
curl -fsSL https://raw.githubusercontent.com/MikhailVMV/terminal-config/main/terminal.omp.json -o ~/terminal.omp.json
```

## Личные (машинно-специфичные) настройки

Не коммить их в репозиторий — держи локально, они подхватятся автоматически:
- PowerShell: `…/PowerShell/profile.local.ps1`
- zsh: `~/.zshrc.local`

Пример `~/.zshrc.local`:
```bash
alias apt='sudo nala'
```

## Файлы

| Файл | Куда ставится |
|---|---|
| `terminal.omp.json` | `~/terminal.omp.json` (Win и WSL) |
| `Microsoft.PowerShell_profile.ps1` | `$PROFILE` (PowerShell 7) |
| `zshrc` | `~/.zshrc` (WSL) |
| `setup-windows.ps1` | установщик Windows |
| `setup-linux.sh` | установщик WSL/Linux |

delta ставится, но как git-pager не включается автоматически. Включить — командами, которые печатает установщик в конце.
