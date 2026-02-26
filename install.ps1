# Islands Dark Theme Installer for Antigravity on Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Installer for Windows (Antigravity)" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Antigravity is installed
$agyPath = Get-Command "agy" -ErrorAction SilentlyContinue
if (-not $agyPath) {
    # Try to find agy in common locations (placeholder paths as per typical install)
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Antigravity\bin\agy.cmd",
        "$env:ProgramFiles\Antigravity\bin\agy.cmd",
        "${env:ProgramFiles(x86)}\Antigravity\bin\agy.cmd"
    )

    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Host "Error: Antigravity CLI (agy) not found!" -ForegroundColor Red
        Write-Host "Please install Antigravity and make sure 'agy' command is in your PATH."
        Write-Host "You can do this by:"
        Write-Host "  1. Open Antigravity"
        Write-Host "  2. Press Ctrl+Shift+P"
        Write-Host "  3. Type 'Shell Command: Install agy command in PATH'"
        exit 1
    }
}

Write-Host "Antigravity CLI found" -ForegroundColor Green

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "Step 1: Installing Islands Dark theme extension..."

# Install by copying to Antigravity extensions directory
$extDir = "$env:USERPROFILE\.antigravity\extensions\nxfx21.islands-dark-1.0.0"
if (Test-Path $extDir) {
    Remove-Item -Recurse -Force $extDir
}
New-Item -ItemType Directory -Path $extDir -Force | Out-Null
Copy-Item "$scriptDir\package.json" "$extDir\" -Force
Copy-Item "$scriptDir\themes" "$extDir\themes" -Recurse -Force

if (Test-Path "$extDir\themes") {
    Write-Host "Theme extension installed to $extDir" -ForegroundColor Green
}
else {
    Write-Host "Failed to install theme extension" -ForegroundColor Red
    exit 1
}

# Register extension in extensions.json so Antigravity discovers it
$extJsonPath = "$env:USERPROFILE\.antigravity\extensions\extensions.json"

# Remove extensions.json so Antigravity rebuilds it cleanly on next launch
# (incorporating upstream fix to prevent invalid state)
if (Test-Path $extJsonPath) {
    Remove-Item $extJsonPath -Force
    Write-Host "Cleared extensions.json (Antigravity will rebuild it)" -ForegroundColor Green
}

try {
    $extensions = @()
    if (Test-Path $extJsonPath) {
        $extensions = Get-Content $extJsonPath -Raw | ConvertFrom-Json
    }

    # Remove any existing Islands Dark entry
    $extensions = @($extensions | Where-Object {
            $_.identifier.id -ne 'nxfx21.islands-dark' -and
            $_.identifier.id -ne 'bwya77.islands-dark'
        })

    # Add new entry
    $newEntry = [PSCustomObject]@{
        identifier       = [PSCustomObject]@{ id = 'nxfx21.islands-dark' }
        version          = '1.0.0'
        location         = [PSCustomObject]@{
            '$mid' = 1
            path   = "$env:USERPROFILE\.antigravity\extensions\nxfx21.islands-dark-1.0.0"
            scheme = 'file'
        }
        relativeLocation = 'nxfx21.islands-dark-1.0.0'
    }
    $extensions += $newEntry

    $extensions | ConvertTo-Json -Depth 10 -Compress | Set-Content $extJsonPath
    Write-Host "Extension registered" -ForegroundColor Green
}
catch {
    Write-Host "Could not register extension automatically" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Installing Custom UI Style extension..."
try {
    agy --install-extension subframe7536.custom-ui-style --force 2>&1 | Out-Null
    Write-Host "Custom UI Style extension installed" -ForegroundColor Green
}
catch {
    Write-Host "Could not install Custom UI Style extension automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from the Extensions marketplace"
}

Write-Host ""
Write-Host "Step 3: Installing Bear Sans UI fonts..."
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

# Try user fonts first
if (-not (Test-Path $fontDir)) {
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
}

try {
    $fonts = Get-ChildItem "$scriptDir\fonts\*.otf"
    foreach ($font in $fonts) {
        try {
            Copy-Item $font.FullName $fontDir -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Silently continue if copy fails
        }
    }

    Write-Host "Fonts installed" -ForegroundColor Green
    Write-Host "   Note: You may need to restart applications to use the new fonts" -ForegroundColor DarkGray
}
catch {
    Write-Host "Could not install fonts automatically" -ForegroundColor Yellow
    Write-Host "   Please manually install the fonts from the 'fonts/' folder"
    Write-Host "   Select all .otf files and right-click > Install"
}

Write-Host ""
Write-Host "Step 4: Applying Antigravity settings..."
$settingsDir = "$env:APPDATA\antigravity\User"
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$settingsFile = Join-Path $settingsDir "settings.json"

# Backup existing settings if they exist
if (Test-Path $settingsFile) {
    $backupFile = "$settingsFile.pre-islands-dark"
    Copy-Item $settingsFile $backupFile -Force
    Write-Host "Existing settings.json backed up to:" -ForegroundColor Yellow
    Write-Host "   $backupFile"
    Write-Host "   You can restore your old settings from this file if needed."
}

# Copy Islands Dark settings
Copy-Item "$scriptDir\settings.json" $settingsFile -Force
Write-Host "Islands Dark settings applied" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Enabling Custom UI Style..."

# Check if this is the first run
$firstRunFile = Join-Path $scriptDir ".islands_dark_first_run"
if (-not (Test-Path $firstRunFile)) {
    New-Item -ItemType File -Path $firstRunFile | Out-Null
    Write-Host ""
    Write-Host "Important Notes:" -ForegroundColor Yellow
    Write-Host "   - IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    Write-Host "   - After Antigravity reloads, you may see a 'corrupt installation' warning"
    Write-Host "   - This is expected - click the gear icon and select 'Don't Show Again'"
    Write-Host ""
    Read-Host "Press Enter to continue and reload Antigravity"
}

Write-Host "   Applying CSS customizations..."

Write-Host ""
Write-Host "Islands Dark theme has been installed!" -ForegroundColor Green
Write-Host "   Antigravity will now restart to apply the custom UI style."
Write-Host ""

# Quit Antigravity and relaunch so Custom UI Style fully initializes and patches CSS
Write-Host "   Closing Antigravity..." -ForegroundColor Cyan
Stop-Process -Name "Antigravity" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host "   Relaunching Antigravity..." -ForegroundColor Cyan
Start-Process "agy" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "If the CSS customizations are not applied, open the Command Palette" -ForegroundColor Yellow
Write-Host "(Ctrl+Shift+P) and run: Custom UI Style: Reload" -ForegroundColor Yellow

Start-Sleep -Seconds 3