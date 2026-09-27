#Requires -Version 7.0
<#
  setup-windows.ps1 — разворачивает терминал (PowerShell 7 + CMD/Clink):
  наши конфиги (тема, профиль) тянутся из GitHub, стандартный софт — из winget.
  Идемпотентен: и на новой, и на текущей машине. История НЕ трогается.
  Запуск см. в README.
#>
$Repo   = 'MikhailVMV/terminal-config'
$Branch = 'main'
$Base   = "https://raw.githubusercontent.com/$Repo/$Branch"

# --- Самоповышение до администратора (Defender + шрифт) ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Нужны права администратора — перезапускаю с запросом UAC..." -ForegroundColor Yellow
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""
    return
}

$ErrorActionPreference = 'Continue'
function Info($m){ Write-Host "==> $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "!!  $m" -ForegroundColor Yellow }

# --- 1. Пакеты через winget ---
$pkgs = @(
    'JanDeDobbeleer.OhMyPosh','chrisant996.Clink','ajeetdsouza.zoxide',
    'eza-community.eza','sharkdp.bat','sharkdp.fd','BurntSushi.ripgrep.MSVC',
    'dandavison.delta','junegunn.fzf','Git.Git'
)
foreach ($id in $pkgs) {
    Info "winget: $id"
    winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
}
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')

# --- 2. Модули PowerShell (в пользователя) ---
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
}
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
foreach ($m in 'PSFzf','Terminal-Icons','CompletionPredictor','posh-git') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Info "Install-Module: $m"; Install-Module $m -Scope CurrentUser -Force -AllowClobber
    } else { Info "модуль уже установлен: $m" }
}

# --- 3. Nerd Font (Meslo) + Windows Terminal ---
Info "Устанавливаю Meslo Nerd Font"
oh-my-posh font install meslo | Out-Null
$fontFace = 'MesloLGM Nerd Font'
$wt = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($wt) {
    try {
        $data = Get-Content $wt -Raw | ConvertFrom-Json -AsHashtable
        if (-not $data.profiles)          { $data.profiles = @{} }
        if (-not $data.profiles.defaults) { $data.profiles.defaults = @{} }
        $data.profiles.defaults.font = @{ face = $fontFace }
        ($data | ConvertTo-Json -Depth 32) | Set-Content $wt -Encoding utf8
        Info "Шрифт прописан в Windows Terminal: $fontFace"
    } catch { Warn "Не смог отредактировать settings.json ($($_.Exception.Message)). Задай шрифт '$fontFace' вручную." }
} else { Warn "settings.json Windows Terminal не найден — задай шрифт '$fontFace' вручную." }

# --- 4. Defender: исключение процесса oh-my-posh (ускоряет старт) ---
try {
    Add-MpPreference -ExclusionProcess 'oh-my-posh.exe' -ErrorAction Stop
    Info "Defender: исключён процесс oh-my-posh.exe"
    $ompCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($ompCmd) {
        $real = (Get-Item $ompCmd.Source).Target
        $ompDir = if ($real) { Split-Path $real -Parent } else { Split-Path $ompCmd.Source -Parent }
        if ($ompDir -and $ompDir -notmatch 'WindowsApps') {
            Add-MpPreference -ExclusionPath $ompDir -ErrorAction SilentlyContinue
            Info "Defender: исключён каталог $ompDir"
        }
    }
} catch { Warn "Не смог добавить исключение Defender: $($_.Exception.Message)" }

# --- 5. Тема (из GitHub) ---
Invoke-WebRequest "$Base/terminal.omp.json" -OutFile "$HOME\terminal.omp.json" -UseBasicParsing
Info "Тема: $HOME\terminal.omp.json"

# --- 6. Профиль PowerShell (из GitHub) ---
if (Test-Path $PROFILE) { Copy-Item $PROFILE "$PROFILE.bak" -Force; Info "Старый профиль сохранён: $PROFILE.bak" }
New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
Invoke-WebRequest "$Base/Microsoft.PowerShell_profile.ps1" -OutFile $PROFILE -UseBasicParsing
Info "Профиль: $PROFILE"

# --- 7. CMD / Clink ---
$clinkDir = "$env:LOCALAPPDATA\clink"
New-Item -ItemType Directory -Force -Path $clinkDir | Out-Null
Set-Content "$clinkDir\oh-my-posh.lua" -Value 'load(io.popen(''oh-my-posh init cmd --config "~/terminal.omp.json"''):read("*a"))()' -Encoding ascii
try { Invoke-WebRequest 'https://raw.githubusercontent.com/shunsambongi/clink-zoxide/master/zoxide.lua' -OutFile "$clinkDir\zoxide.lua" -UseBasicParsing; Info "zoxide.lua для cmd установлен" } catch { Warn "Не скачал zoxide.lua: $($_.Exception.Message)" }
$cc = "$clinkDir\clink-completions"
if (Test-Path $cc) { git -C $cc pull --quiet } else { git clone --quiet https://github.com/vladimir-kotikov/clink-completions $cc }
$cg = "$clinkDir\clink-gizmos"
if (Test-Path $cg) { git -C $cg pull --quiet } else { git clone --quiet https://github.com/chrisant996/clink-gizmos $cg }
$clinkExe = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\clink.bat",
    "${env:ProgramFiles(x86)}\clink\clink.bat",
    "$env:ProgramFiles\clink\clink.bat"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $clinkExe) { $clinkExe = (Get-Command clink -ErrorAction SilentlyContinue).Source }
if ($clinkExe) {
    & $clinkExe installscripts "$cc" | Out-Null
    & $clinkExe installscripts "$cg" | Out-Null
    Info "CMD/Clink настроен (OMP, zoxide, completions, fzf)"
} else {
    Warn "clink не найден в этой сессии — открой cmd и выполни один раз:"
    Write-Host "    clink installscripts `"$cc`""
    Write-Host "    clink installscripts `"$cg`""
}

Write-Host ""
Info "Готово. Перезапусти PowerShell и CMD."
Warn "delta установлена, но как git-pager НЕ включена. Включить:"
Write-Host "    git config --global core.pager delta"
Write-Host "    git config --global interactive.diffFilter 'delta --color-only'"
Write-Host "    git config --global delta.navigate true"
Read-Host "Enter для выхода"
