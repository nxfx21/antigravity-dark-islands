# Islands Dark Theme Bootstrap Installer for Antigravity
# One-liner: irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Bootstrap Installer for Antigravity" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

$RepoUrl = "https://github.com/bwya77/vscode-dark-islands.git"
$InstallDir = "$env:USERPROFILE\.islands-dark-temp"

Write-Host "Step 1: Downloading Islands Dark..."
Write-Host "   Repository: $RepoUrl"

# Remove old temp directory if exists
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}

# Clone repository
try {
    git clone "$RepoUrl" "$InstallDir" --quiet
    Write-Host "Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to download Islands Dark" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Running installer..."
Write-Host ""

# Run installer
Set-Location "$InstallDir"
.\install.ps1

# Cleanup
Write-Host ""
Write-Host "Step 3: Cleaning up..."
$remove = Read-Host "   Remove temporary files? (y/n)"
if ($remove -match "^[Yy]") {
    Remove-Item -Recurse -Force "$InstallDir"
    Write-Host "Temporary files removed" -ForegroundColor Green
} else {
    Write-Host "Files kept at: $InstallDir"
}

Write-Host ""
Write-Host "Done! Enjoy your Islands Dark theme on Antigravity!" -ForegroundColor Green