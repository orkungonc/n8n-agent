[CmdletBinding(SupportsShouldProcess)]
param([string]$InstallDir = (Join-Path $env:USERPROFILE 'n8n-agent'))
$ErrorActionPreference = 'Stop'
$agentPath = [IO.Path]::GetFullPath((Join-Path $InstallDir 'agent.ps1'))
$startupFile = Join-Path ([Environment]::GetFolderPath('Startup')) 'n8n-agent.cmd'

# Önce otomatik yeniden başlatma girişini kaldır.
if (Test-Path -LiteralPath $startupFile) {
    if ($PSCmdlet.ShouldProcess($startupFile, 'Remove startup entry')) {
        Remove-Item -LiteralPath $startupFile -Force
    }
}
# Yalnız bu tam dosya yolunu -File ile çalıştıran PowerShell süreçleri.
$escaped = [regex]::Escape($agentPath)
$pattern = '(?i)(?:^|\s)-File\s+(?:"' + $escaped + '"|'+ $escaped + '(?=\s|$))'
$processes = Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
    $_.Name -in @('powershell.exe', 'pwsh.exe') -and
    $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine -match $pattern
}
foreach ($process in $processes) {
    if ($PSCmdlet.ShouldProcess([string]$process.ProcessId, 'Stop n8n agent')) {
        Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
    }
}
foreach ($file in @($agentPath, (Join-Path $InstallDir 'setup.ps1'),
                    (Join-Path $env:USERPROFILE '.n8n-agent\n8n-key.txt'))) {
    if (Test-Path -LiteralPath $file) {
        if ($PSCmdlet.ShouldProcess($file, 'Remove agent file')) {
            Remove-Item -LiteralPath $file -Force
        }
    }
}
Write-Host 'Islem tamamlandi. n8n API anahtarini n8n ayarlarindan iptal edin.'
Write-Host 'Ek servis/Zamanlanmis Gorev kurulumlarini ayrica kontrol edin.'
