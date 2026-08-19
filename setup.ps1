$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/orkungonc/n8n-agent.git'
$InstallDir = Join-Path $env:USERPROFILE 'n8n-agent'
$StateDir = Join-Path $env:USERPROFILE '.n8n-agent'

Write-Host 'n8n Agent kurulumu basliyor...'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'Git bulunamadi. Winget ile kuruluyor...'
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'Git ve winget bulunamadi. Git for Windows kurulumu gerekiyor.'
  }
  winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
  $env:Path += ';C:\Program Files\Git\cmd'
}

if (!(Test-Path $InstallDir)) {
  Write-Host 'GitHub deposu bilgisayara indiriliyor...'
  git clone $RepoUrl $InstallDir
} else {
  Write-Host 'n8n-agent klasoru zaten var, guncelleniyor...'
  Push-Location $InstallDir
  git pull --ff-only
  Pop-Location
}

New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

Write-Host ''
Write-Host 'n8n API anahtarini girin. Ekranda gorunmeyecek.'
$key = Read-Host 'n8n API Key' -AsSecureString
$key | ConvertFrom-SecureString | Set-Content (Join-Path $StateDir 'n8n-key.txt') -Encoding UTF8

$startup = [Environment]::GetFolderPath('Startup')
$cmdPath = Join-Path $startup 'n8n-agent.cmd'
$agentPath = Join-Path $InstallDir 'agent.ps1'
$cmd = @"
@echo off
start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$agentPath"
"@
Set-Content -Path $cmdPath -Value $cmd -Encoding ASCII

Write-Host 'Agent simdi baslatiliyor...'
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$agentPath)

Write-Host ''
Write-Host 'KURULUM TAMAMLANDI.'
Write-Host 'Bilgisayar acildiginda n8n-agent otomatik baslayacak.'
Write-Host 'Log dosyasi:' (Join-Path $StateDir 'agent.log')
Write-Host 'Bu pencereyi kapatabilirsiniz.'
