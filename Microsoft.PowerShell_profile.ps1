# ==== terminal-config: профиль PowerShell 7 (github.com/MikhailVMV/terminal-config) ====

# История + предсказания (файл истории отдельный, не сбрасывается)
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
Set-PSReadLineOption -Colors @{
    Command   = 'Cyan'
    Parameter = 'DarkCyan'
    String    = 'Yellow'
    Comment   = 'Green'
    Error     = 'Red'
}
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Промпт — синхронно (нужен сразу)
oh-my-posh init pwsh --config "$HOME\terminal.omp.json" | Invoke-Expression

# zoxide — умный cd: "z proxmox" (дёшево, синхронно)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Тяжёлые модули — отложенно, после появления промпта (не тормозят старт)
$null = Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r' -PSReadlineChordProvider 'Ctrl+t' -ErrorAction SilentlyContinue
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    Import-Module CompletionPredictor -ErrorAction SilentlyContinue
    Import-Module posh-git -ErrorAction SilentlyContinue
    Import-Module Microsoft.WinGet.CommandNotFound -ErrorAction SilentlyContinue
}

# Локальные машинно-специфичные настройки (не в репозитории)
$__local = Join-Path (Split-Path $PROFILE) 'profile.local.ps1'
if (Test-Path $__local) { . $__local }
