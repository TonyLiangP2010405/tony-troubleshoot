[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CaseRoot,

    [Parameter(Mandatory = $true)]
    [ValidateSet("initialized", "cataloging", "discovering", "triaging", "deep_dive", "collecting", "auditing", "complete", "incomplete", "blocked")]
    [string]$CaseStatus,

    [Parameter(Mandatory = $true)]
    [string]$NextAction,

    [Parameter(Mandatory = $true)]
    [string]$LogEntry,

    [string]$LastCompletedRecord = "",
    [string]$ActiveBlockers = "none",

    [string]$SessionNonce = "",

    [ValidateSet("", "pending", "complete")]
    [string]$IntakeStatus = "",

    [ValidateSet("", "pending", "complete", "none_provided", "blocked")]
    [string]$CustomerFileReviewStatus = "",

    [ValidateSet("", "not_started", "complete", "unavailable")]
    [string]$OfficialResearchStatus = "",

    [ValidateSet("", "not_started", "provisional", "confirmed", "inconclusive")]
    [string]$ClassificationStatus = "",

    [ValidateSet("", "power", "audio", "video", "network", "control", "protocol_conflict", "other")]
    [string]$PrimaryCategory = "",

    [ValidateSet("power", "audio", "video", "network", "control", "protocol_conflict", "other")]
    [string[]]$SecondaryCategory,

    [ValidateSet("", "low", "medium", "high")]
    [string]$ClassificationConfidence = ""
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
$schemaVersion = if ($oldCheckpoint.PSObject.Properties.Name -contains "schema_version") {
    [int]$oldCheckpoint.schema_version
} else {
    1
}
if ($schemaVersion -ge 3) {
    foreach ($relativePath in @("intake.md", "user-actions.csv", "classification.md")) {
        $fullPath = Join-Path $resolvedCaseRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            throw "Required schema v3 case file is missing: $fullPath"
        }
    }
}
if ($schemaVersion -ge 4) {
    if (-not ($oldCheckpoint.PSObject.Properties.Name -contains "session_nonce") -or -not $oldCheckpoint.session_nonce) {
        throw "Schema v4 checkpoint is missing session_nonce."
    }
    if (-not $SessionNonce) {
        throw "SessionNonce is required for a session-scoped case."
    }
    if (-not [string]::Equals([string]$oldCheckpoint.session_nonce, $SessionNonce, [System.StringComparison]::Ordinal)) {
        throw "SessionNonce does not match this case. Do not resume a different session's records."
    }
}
if ($schemaVersion -ge 5) {
    $officialResearchPath = Join-Path $resolvedCaseRoot "wyrestorm-official-research.md"
    if (-not (Test-Path -LiteralPath $officialResearchPath -PathType Leaf)) {
        throw "Required schema v5 case file is missing: $officialResearchPath"
    }
}
if ($schemaVersion -ge 6) {
    foreach ($relativePath in @("source\customer-file-index.csv", "customer-file-review.md")) {
        $fullPath = Join-Path $resolvedCaseRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            throw "Required schema v6 case file is missing: $fullPath"
        }
    }
}

$documents = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "source\api-doc-index.csv"))
$customerFiles = if ($schemaVersion -ge 6) {
    @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "source\customer-file-index.csv"))
} else {
    @()
}
$commands = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "command-catalog.csv"))
$devices = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "device-inventory.csv"))
$ledger = @(Import-Csv -LiteralPath (Join-Path $resolvedCaseRoot "progress-ledger.csv"))
$now = (Get-Date).ToString("o")

$scanMode = if ($oldCheckpoint.PSObject.Properties.Name -contains "scan_mode" -and $oldCheckpoint.scan_mode) {
    [string]$oldCheckpoint.scan_mode
} else {
    "audit"
}
$sessionScope = if ($oldCheckpoint.PSObject.Properties.Name -contains "session_scope" -and $oldCheckpoint.session_scope) {
    [string]$oldCheckpoint.session_scope
} else {
    "legacy_unspecified"
}
$checkpointSessionNonce = if ($oldCheckpoint.PSObject.Properties.Name -contains "session_nonce" -and $oldCheckpoint.session_nonce) {
    [string]$oldCheckpoint.session_nonce
} else {
    $null
}
$oldIntakeStatus = if ($oldCheckpoint.PSObject.Properties.Name -contains "intake_status" -and $oldCheckpoint.intake_status) {
    [string]$oldCheckpoint.intake_status
} else {
    "pending"
}
$intakeStatusValue = if ($IntakeStatus) { $IntakeStatus } else { $oldIntakeStatus }
$intakeCompletedAtValue = if ($IntakeStatus -eq "complete" -and $oldIntakeStatus -ne "complete") {
    $now
} elseif ($IntakeStatus -eq "pending") {
    $null
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "intake_completed_at") {
    $oldCheckpoint.intake_completed_at
} else {
    $null
}
$oldCustomerFileReviewStatus = if ($oldCheckpoint.PSObject.Properties.Name -contains "customer_file_review_status" -and $oldCheckpoint.customer_file_review_status) {
    [string]$oldCheckpoint.customer_file_review_status
} elseif ($schemaVersion -ge 6) {
    "pending"
} else {
    "legacy_untracked"
}
$customerFileReviewStatusValue = if ($CustomerFileReviewStatus) {
    $CustomerFileReviewStatus
} else {
    $oldCustomerFileReviewStatus
}
$customerFileReviewUpdatedAtValue = if ($PSBoundParameters.ContainsKey("CustomerFileReviewStatus")) {
    $now
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "customer_file_review_updated_at") {
    $oldCheckpoint.customer_file_review_updated_at
} else {
    $null
}
$oldOfficialResearchStatus = if ($oldCheckpoint.PSObject.Properties.Name -contains "official_research_status" -and $oldCheckpoint.official_research_status) {
    [string]$oldCheckpoint.official_research_status
} elseif ($schemaVersion -ge 5) {
    "not_started"
} else {
    "legacy_untracked"
}
$officialResearchStatusValue = if ($OfficialResearchStatus) {
    $OfficialResearchStatus
} else {
    $oldOfficialResearchStatus
}
$officialResearchUpdatedAtValue = if ($PSBoundParameters.ContainsKey("OfficialResearchStatus")) {
    $now
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "official_research_updated_at") {
    $oldCheckpoint.official_research_updated_at
} else {
    $null
}

$classificationStatusValue = if ($ClassificationStatus) {
    $ClassificationStatus
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "classification_status" -and $oldCheckpoint.classification_status) {
    [string]$oldCheckpoint.classification_status
} else {
    "not_started"
}
$primaryCategoryValue = if ($PrimaryCategory) {
    $PrimaryCategory
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "primary_category" -and $oldCheckpoint.primary_category) {
    [string]$oldCheckpoint.primary_category
} else {
    $null
}
$secondaryCategoriesValue = if ($PSBoundParameters.ContainsKey("SecondaryCategory")) {
    @($SecondaryCategory | Select-Object -Unique)
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "secondary_categories") {
    @($oldCheckpoint.secondary_categories)
} else {
    @()
}
$classificationConfidenceValue = if ($ClassificationConfidence) {
    $ClassificationConfidence
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "classification_confidence" -and $oldCheckpoint.classification_confidence) {
    [string]$oldCheckpoint.classification_confidence
} else {
    $null
}
$classificationWasUpdated = $PSBoundParameters.ContainsKey("ClassificationStatus") -or
    $PSBoundParameters.ContainsKey("PrimaryCategory") -or
    $PSBoundParameters.ContainsKey("SecondaryCategory") -or
    $PSBoundParameters.ContainsKey("ClassificationConfidence")
$classificationUpdatedAtValue = if ($classificationWasUpdated) {
    $now
} elseif ($oldCheckpoint.PSObject.Properties.Name -contains "classification_updated_at") {
    $oldCheckpoint.classification_updated_at
} else {
    $null
}
if ($classificationStatusValue -ne "not_started" -and $intakeStatusValue -ne "complete") {
    throw "Complete intake before setting a problem classification."
}
if ($schemaVersion -ge 6 -and $customerFileReviewStatusValue -eq "none_provided" -and $customerFiles.Count -gt 0) {
    throw "Customer files are indexed; CustomerFileReviewStatus cannot be none_provided."
}
if ($schemaVersion -ge 6 -and $customerFileReviewStatusValue -eq "complete") {
    if ($customerFiles.Count -eq 0) {
        throw "No customer files are indexed; use CustomerFileReviewStatus none_provided."
    }
    $unfinishedCustomerFiles = @($customerFiles | Where-Object { $_.review_status -ne "complete" })
    if ($unfinishedCustomerFiles.Count -gt 0) {
        throw "Every indexed customer file must have review_status=complete before completing customer-file review."
    }
}
if ($schemaVersion -ge 6 -and $classificationStatusValue -ne "not_started" -and $customerFileReviewStatusValue -notin @("complete", "none_provided")) {
    throw "Fully review all customer-provided files or record that none were provided before setting a problem classification."
}
if ($schemaVersion -ge 5 -and $classificationStatusValue -ne "not_started" -and $officialResearchStatusValue -notin @("complete", "unavailable")) {
    throw "Complete targeted WyreStorm official research or explicitly mark it unavailable before setting a problem classification."
}
if ($classificationStatusValue -ne "not_started" -and -not $primaryCategoryValue) {
    throw "PrimaryCategory is required when classification has started."
}
if ($classificationStatusValue -eq "not_started" -and ($primaryCategoryValue -or $secondaryCategoriesValue.Count -gt 0 -or $classificationConfidenceValue)) {
    throw "Set ClassificationStatus when recording a category or confidence."
}
$onlineDevices = @($devices | Where-Object { $_.online_status -match "^(?i:online|up|connected|active|true|1)$" })
$cohorts = @($devices | Where-Object { $_.cohort_id } | Select-Object -ExpandProperty cohort_id -Unique)
$completed = @($ledger | Where-Object { $_.status -eq "completed" })
$coreCompleted = @($completed | Where-Object { $_.scan_tier -eq "core" })
$diagnosticCompleted = @($completed | Where-Object { $_.scan_tier -eq "diagnostic" })
$auditCompleted = @($completed | Where-Object { $_.scan_tier -eq "audit" })
$failed = @($ledger | Where-Object { $_.status -eq "failed" })
$blocked = @($ledger | Where-Object { $_.status -in @("blocked", "unsupported") })
$notFinished = @($ledger | Where-Object { $_.status -in @("not_started", "in_progress") })
$checkpoint = [ordered]@{
    schema_version = if ($schemaVersion -ge 3) { $schemaVersion } else { 2 }
    case_id = $oldCheckpoint.case_id
    case_root = $resolvedCaseRoot
    session_scope = $sessionScope
    session_nonce = $checkpointSessionNonce
    scan_mode = $scanMode
    status = $CaseStatus
    intake_status = $intakeStatusValue
    intake_completed_at = $intakeCompletedAtValue
    customer_file_review_status = $customerFileReviewStatusValue
    customer_file_review_updated_at = $customerFileReviewUpdatedAtValue
    official_research_status = $officialResearchStatusValue
    official_research_updated_at = $officialResearchUpdatedAtValue
    classification_status = $classificationStatusValue
    primary_category = $primaryCategoryValue
    secondary_categories = $secondaryCategoriesValue
    classification_confidence = $classificationConfidenceValue
    classification_updated_at = $classificationUpdatedAtValue
    created_at = $oldCheckpoint.created_at
    updated_at = $now
    document_count = $documents.Count
    command_count = $commands.Count
    cohort_count = $cohorts.Count
    online_device_count = $onlineDevices.Count
    matrix_row_count = $ledger.Count
    completed_count = $completed.Count
    failed_count = $failed.Count
    blocked_count = $blocked.Count
    unfinished_count = $notFinished.Count
    core_completed_count = $coreCompleted.Count
    diagnostic_completed_count = $diagnosticCompleted.Count
    audit_completed_count = $auditCompleted.Count
    last_completed_record = if ($LastCompletedRecord) { $LastCompletedRecord } else { $oldCheckpoint.last_completed_record }
    next_action = $NextAction
}

$checkpointTemp = Join-Path $resolvedCaseRoot ("checkpoint.json.tmp-" + [guid]::NewGuid().ToString("N"))
$checkpoint | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $checkpointTemp -Encoding utf8
Move-Item -LiteralPath $checkpointTemp -Destination (Join-Path $resolvedCaseRoot "checkpoint.json") -Force

$handoff = @"
# Session handoff

- Session scope: $sessionScope
- Session nonce: $(if ($checkpointSessionNonce) { $checkpointSessionNonce } else { "legacy-unavailable" })
- Scan mode: $scanMode
- Case status: $CaseStatus
- Intake status: $intakeStatusValue
- Customer file review status: $customerFileReviewStatusValue
- WyreStorm official research status: $officialResearchStatusValue
- Classification: $classificationStatusValue / $(if ($primaryCategoryValue) { $primaryCategoryValue } else { "none" }) / $(if ($classificationConfidenceValue) { $classificationConfidenceValue } else { "none" }) confidence
- Secondary categories: $(if ($secondaryCategoriesValue.Count -gt 0) { $secondaryCategoriesValue -join ", " } else { "none" })
- Last completed record: $(if ($LastCompletedRecord) { $LastCompletedRecord } else { "none recorded" })
- Next action: $NextAction
- Documents / commands: $($documents.Count) / $($commands.Count)
- Cohorts / online devices / selected matrix rows: $($cohorts.Count) / $($onlineDevices.Count) / $($ledger.Count)
- Completed / failed / blocked / unfinished: $($completed.Count) / $($failed.Count) / $($blocked.Count) / $($notFinished.Count)
- Completed by tier (core / diagnostic / audit): $($coreCompleted.Count) / $($diagnosticCompleted.Count) / $($auditCompleted.Count)
- Active blockers: $ActiveBlockers
- Resume instruction: only within the same conversation and with the exact CaseRoot and matching session nonce, read this file, ``checkpoint.json``, ``intake.md``, ``user-actions.csv``, ``source/customer-file-index.csv``, ``customer-file-review.md``, ``wyrestorm-official-research.md``, ``classification.md``, all other CSV ledgers, and the tail of ``checkpoint-log.md``
- Last updated: $now
"@
$handoffTemp = Join-Path $resolvedCaseRoot ("session-handoff.md.tmp-" + [guid]::NewGuid().ToString("N"))
Set-Content -LiteralPath $handoffTemp -Value $handoff -Encoding utf8
Move-Item -LiteralPath $handoffTemp -Destination (Join-Path $resolvedCaseRoot "session-handoff.md") -Force

Add-Content -LiteralPath (Join-Path $resolvedCaseRoot "checkpoint-log.md") -Value "`n- $now — $LogEntry"

Write-Output (Join-Path $resolvedCaseRoot "checkpoint.json")
