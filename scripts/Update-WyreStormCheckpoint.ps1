[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CaseRoot,

    [Parameter(Mandatory = $true)]
    [ValidateSet("initialized", "cataloging", "discovering", "collecting", "auditing", "complete", "incomplete", "blocked")]
    [string]$CaseStatus,

    [Parameter(Mandatory = $true)]
    [string]$NextAction,

    [Parameter(Mandatory = $true)]
    [string]$LogEntry,

    [string]$LastCompletedRecord = "",
    [string]$ActiveBlockers = "none"
)

$ErrorActionPreference = "Stop"
$resolvedCaseRoot = (Resolve-Path -LiteralPath $CaseRoot).Path
$requiredFiles = @(
    "checkpoint.json",
    "command-catalog.csv",
    "device-inventory.csv",
    "progress-ledger.csv",
    "coverage-audit.csv",
    "source\api-doc-index.csv"
)
foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $resolvedCaseRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Required case file is missing: $fullPath"
    }
}

$oldCheckpoint = Get-Content -Raw -LiteralPath (Join-Path $resolvedCaseRoot "checkpoint.json") | ConvertFrom-Json
$documents = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "source\api-doc-index.csv"))
$commands = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "command-catalog.csv"))
$devices = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "device-inventory.csv"))
$ledger = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "progress-ledger.csv"))

$onlineDevices = @($devices | Where-Object { $_.online_status -match "^(?i:online|up|connected|active|true|1)$" })
$completed = @($ledger | Where-Object { $_.status -eq "completed" })
$failed = @($ledger | Where-Object { $_.status -eq "failed" })
$blocked = @($ledger | Where-Object { $_.status -in @("blocked", "unsupported") })
$notFinished = @($ledger | Where-Object { $_.status -in @("not_started", "in_progress") })
$now = (Get-Date).ToString("o")

$checkpoint = [ordered]@{
    schema_version = 1
    case_id = $oldCheckpoint.case_id
    case_root = $resolvedCaseRoot
    status = $CaseStatus
    created_at = $oldCheckpoint.created_at
    updated_at = $now
    document_count = $documents.Count
    command_count = $commands.Count
    online_device_count = $onlineDevices.Count
    matrix_row_count = $ledger.Count
    completed_count = $completed.Count
    failed_count = $failed.Count
    blocked_count = $blocked.Count
    unfinished_count = $notFinished.Count
    last_completed_record = if ($LastCompletedRecord) { $LastCompletedRecord } else { $oldCheckpoint.last_completed_record }
    next_action = $NextAction
}

$checkpointTemp = Join-Path $resolvedCaseRoot ("checkpoint.json.tmp-" + [guid]::NewGuid().ToString("N"))
$checkpoint | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $checkpointTemp -Encoding utf8
Move-Item -LiteralPath $checkpointTemp -Destination (Join-Path $resolvedCaseRoot "checkpoint.json") -Force

$handoff = @"
# Session handoff

- Case status: $CaseStatus
- Last completed record: $(if ($LastCompletedRecord) { $LastCompletedRecord } else { "none recorded" })
- Next action: $NextAction
- Documents / commands: $($documents.Count) / $($commands.Count)
- Online devices / matrix rows: $($onlineDevices.Count) / $($ledger.Count)
- Completed / failed / blocked / unfinished: $($completed.Count) / $($failed.Count) / $($blocked.Count) / $($notFinished.Count)
- Active blockers: $ActiveBlockers
- Resume instruction: read this file, ``checkpoint.json``, all CSV ledgers, and the tail of ``checkpoint-log.md`` before issuing a command
- Last updated: $now
"@
$handoffTemp = Join-Path $resolvedCaseRoot ("session-handoff.md.tmp-" + [guid]::NewGuid().ToString("N"))
Set-Content -LiteralPath $handoffTemp -Value $handoff -Encoding utf8
Move-Item -LiteralPath $handoffTemp -Destination (Join-Path $resolvedCaseRoot "session-handoff.md") -Force

Add-Content -LiteralPath (Join-Path $resolvedCaseRoot "checkpoint-log.md") -Value "`n- $now — $LogEntry"

Write-Output (Join-Path $resolvedCaseRoot "checkpoint.json")
