# Quick Islands Dark Settings Merger for Antigravity
# This script merges Islands Dark theme settings into Antigravity

param()

$ErrorActionPreference = "Stop"

Write-Host "Merging Islands Dark settings into Antigravity..." -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$antigravitySettingsPath = "$env:APPDATA\Antigravity\User\settings.json"

# Check if Antigravity settings exist
if (-not (Test-Path $antigravitySettingsPath)) {
    Write-Host "Error: Antigravity settings not found at: $antigravitySettingsPath" -ForegroundColor Red
    exit 1
}

# Backup current settings
$backupPath = "$antigravitySettingsPath.backup"
Copy-Item $antigravitySettingsPath $backupPath -Force
Write-Host "Backed up current settings to: $backupPath" -ForegroundColor Green

# Function to strip JSONC (comments and trailing commas)
function Strip-Jsonc {
    param([string]$Text)
    $Text = $Text -replace '//.*$', ''
    $Text = $Text -replace '/\*[\s\S]*?\*/', ''
    $Text = $Text -replace ',\s*([}\]])', '$1'
    return $Text
}

# Read current Antigravity settings
$currentSettingsRaw = Get-Content $antigravitySettingsPath -Raw
$currentSettings = (Strip-Jsonc $currentSettingsRaw) | ConvertFrom-Json

# Read Islands Dark settings
$islandsSettingsRaw = Get-Content "$scriptDir\settings.json" -Raw
$islandsSettings = (Strip-Jsonc $islandsSettingsRaw) | ConvertFrom-Json

# Merge settings (Islands Dark takes precedence)
$mergedSettings = @{}

# Start with current settings
$currentSettings.PSObject.Properties | ForEach-Object {
    $mergedSettings[$_.Name] = $_.Value
}

# Override/add Islands Dark settings
$islandsSettings.PSObject.Properties | ForEach-Object {
    $mergedSettings[$_.Name] = $_.Value
}

# Deep merge custom-ui-style.stylesheet
$stylesheetKey = 'custom-ui-style.stylesheet'
if ($currentSettings.$stylesheetKey -and $islandsSettings.$stylesheetKey) {
    $mergedStylesheet = @{}
    
    $currentSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
        $mergedStylesheet[$_.Name] = $_.Value
    }
    
    $islandsSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
        $mergedStylesheet[$_.Name] = $_.Value
    }
    
    $mergedSettings[$stylesheetKey] = [PSCustomObject]$mergedStylesheet
}

# Write merged settings
[PSCustomObject]$mergedSettings | ConvertTo-Json -Depth 100 | Set-Content $antigravitySettingsPath

Write-Host "Settings merged successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart Antigravity"
Write-Host "  2. Theme should be automatically applied"
Write-Host "  3. If you see warnings about corrupt installation, click 'Don't Show Again'"
Write-Host ""
