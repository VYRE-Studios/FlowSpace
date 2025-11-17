# FlowSpace Setup - installs deps, starts services
param([string]$InstallPath = "C:\Users\$env:USERNAME\FlowSpace")
Write-Host "Setting up FlowSpace..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$InstallPath\data\minio" -Force | Out-Null
New-Item -ItemType Directory -Path "$InstallPath\logs" -Force | Out-Null
if (Test-Path "$InstallPath\backend\package.json") {
  Push-Location "$InstallPath\backend"
  npm install --production
  npm run build
  Pop-Location
}
Write-Host "Setup complete!" -ForegroundColor Green
