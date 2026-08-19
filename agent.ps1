$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$TasksDir = Join-Path $Root 'tasks'
$StateDir = Join-Path $env:USERPROFILE '.n8n-agent'
$StateFile = Join-Path $StateDir 'processed.json'
$KeyFile = Join-Path $StateDir 'n8n-key.txt'
$LogFile = Join-Path $StateDir 'agent.log'
$N8nBase = 'http://localhost:5678/api/v1'

New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
if (!(Test-Path $StateFile)) { '{}' | Set-Content -Encoding UTF8 $StateFile }
if (!(Test-Path $KeyFile)) { throw "n8n API anahtari bulunamadi. setup.ps1 calistirin." }

function Log($msg) {
  $line = "$(Get-Date -Format s) $msg"
  Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Get-Key {
  $secure = Get-Content $KeyFile | ConvertTo-SecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Invoke-N8n($method, $path, $body=$null) {
  $headers = @{ 'X-N8N-API-KEY' = (Get-Key); 'Accept'='application/json' }
  $uri = "$N8nBase$path"
  if ($null -eq $body) {
    return Invoke-RestMethod -Uri $uri -Headers $headers -Method $method
  }
  return Invoke-RestMethod -Uri $uri -Headers $headers -Method $method -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 100)
}

function Get-WorkflowByName($name) {
  $r = Invoke-N8n 'GET' '/workflows?limit=250'
  return @($r.data) | Where-Object { $_.name -eq $name } | Select-Object -First 1
}

function Apply-Task($task) {
  if ($task.action -ne 'upsert_workflow') { throw "Desteklenmeyen action: $($task.action)" }
  $wf = $task.workflow
  if (!$wf.name) { throw 'Workflow name eksik' }

  $existing = Get-WorkflowByName $wf.name
  if ($null -eq $existing) {
    $created = Invoke-N8n 'POST' '/workflows' $wf
    Log "CREATE ok: $($wf.name) id=$($created.id)"
    return
  }

  try {
    $updated = Invoke-N8n 'PUT' "/workflows/$($existing.id)" $wf
    Log "UPDATE ok: $($wf.name) id=$($existing.id)"
  } catch {
    Log "UPDATE failed for $($wf.name): $($_.Exception.Message)"
    throw
  }
}

function Read-ProcessedState {
  $table = @{}
  try {
    $obj = Get-Content $StateFile -Raw | ConvertFrom-Json
    if ($null -ne $obj) {
      $obj.PSObject.Properties | ForEach-Object { $table[$_.Name] = [string]$_.Value }
    }
  } catch {
    Log "state reset: $($_.Exception.Message)"
  }
  return $table
}

Log 'agent started'
while ($true) {
  try {
    Push-Location $Root
    git pull --ff-only 2>&1 | ForEach-Object { Log "git: $_" }
    Pop-Location

    $processed = Read-ProcessedState
    Get-ChildItem $TasksDir -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
      $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
      if ($processed[$_.Name] -eq $hash) { return }
      try {
        $task = Get-Content $_.FullName -Raw | ConvertFrom-Json
        Apply-Task $task
        $processed[$_.Name] = $hash
        ($processed | ConvertTo-Json -Depth 20) | Set-Content $StateFile -Encoding UTF8
        Log "processed: $($_.Name)"
      } catch {
        Log "task failed $($_.Name): $($_.Exception.Message)"
      }
    }
  } catch {
    Log "loop error: $($_.Exception.Message)"
  }
  Start-Sleep -Seconds 20
}
