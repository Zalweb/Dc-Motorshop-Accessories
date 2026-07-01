# Runs DC Motorcycle Inventory on an Android emulator with hot reload.
# Boots the emulator if it isn't already running, waits for it, then launches
# the app. Hot reload: press r (reload) / R (restart) / q (quit) in this window.
#
# Usage (from project root):
#   ./tool/run_emulator.ps1
#   ./tool/run_emulator.ps1 -EmulatorId Pixel_9_Pro_XL

param(
  [string]$EmulatorId = ''
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Get-AndroidDeviceId {
  $raw = flutter devices --machine 2>$null | Out-String
  if (-not $raw.Trim()) { return $null }
  try { $devices = $raw | ConvertFrom-Json } catch { return $null }
  foreach ($d in $devices) {
    if ($d.targetPlatform -like 'android*') { return $d.id }
  }
  return $null
}

$deviceId = Get-AndroidDeviceId

if (-not $deviceId) {
  if (-not $EmulatorId) {
    $line = (flutter emulators 2>&1 | Select-String 'android' | Select-Object -First 1).Line
    if ($line) { $EmulatorId = (($line.Trim()) -split '\s+')[0] }
  }
  if (-not $EmulatorId) {
    Write-Error 'No Android emulator found. Create one in Android Studio or run: flutter emulators --create'
    exit 1
  }

  Write-Host "Launching emulator '$EmulatorId'..." -ForegroundColor Cyan
  flutter emulators --launch $EmulatorId

  Write-Host 'Waiting for the emulator to come online...' -ForegroundColor Yellow
  $tries = 0
  while (-not $deviceId -and $tries -lt 60) {
    Start-Sleep -Seconds 3
    $deviceId = Get-AndroidDeviceId
    $tries++
  }
}

if (-not $deviceId) {
  Write-Error 'Emulator did not come online in time. Open it manually, then re-run this script.'
  exit 1
}

Write-Host "Running on $deviceId. Press r = hot reload, R = hot restart, q = quit." -ForegroundColor Green
flutter run -d $deviceId
