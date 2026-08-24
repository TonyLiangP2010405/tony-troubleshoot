[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CaseRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ApiDocument,

    [ValidateSet("triage", "deep", "audit")]
    [string]$ScanMode = "triage",

    [ValidateNotNullOrEmpty()]
    [string]$SessionNonce = ([guid]::NewGuid().ToString("N")),

    [string]$CaseId = ("wyrestorm-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
)

$ErrorActionPreference = "Stop"
$resolvedCaseRoot = [System.IO.Path]::GetFullPath($CaseRoot)

if (Test-Path -LiteralPath $resolvedCaseRoot) {
    $existingItems = @(Get-ChildItem -LiteralPath $resolvedCaseRoot -Force)
    if ($existingItems.Count -gt 0) {
        throw "CaseRoot already exists and is not empty: $resolvedCaseRoot"
    }
} else {
    New-Item -ItemType Directory -Path $resolvedCaseRoot | Out-Null
}

$sourceRoot = Join-Path $resolvedCaseRoot "source"
$apiDocRoot = Join-Path $sourceRoot "api-docs"
$rawRoot = Join-Path $resolvedCaseRoot "raw"
New-Item -ItemType Directory -Path $sourceRoot, $apiDocRoot, $rawRoot | Out-Null

$docRows = @()
$docOrdinal = 0
foreach ($document in $ApiDocument) {
    $docOrdinal += 1
    $uri = $null
    if ([System.Uri]::TryCreate($document, [System.UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @("http", "https")) {
        $docRows += [pscustomobject]@{
            document_id = "DOC-{0:D3}" -f $docOrdinal
            source_type = "url"
            original_source = $document
            preserved_path = ""
            sha256 = ""
            model_series = ""
            firmware_api_version = ""
            indexed_at = (Get-Date).ToString("o")
            notes = "URL recorded; preserve a local copy before collection"
        }
        continue
    }

    if (-not (Test-Path -LiteralPath $document -PathType Leaf)) {
        throw "API document is neither an existing file nor an HTTP(S) URL: $document"
    }

    $sourcePath = (Resolve-Path -LiteralPath $document).Path
    $destinationName = "{0:D3}-{1}" -f $docOrdinal, [System.IO.Path]::GetFileName($sourcePath)
    $destinationPath = Join-Path $apiDocRoot $destinationName
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
    $hash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash.ToLowerInvariant()

    $docRows += [pscustomobject]@{
        document_id = "DOC-{0:D3}" -f $docOrdinal
        source_type = "local-file"
        original_source = $sourcePath
        preserved_path = $destinationPath
        sha256 = $hash
        model_series = ""
        firmware_api_version = ""
        indexed_at = (Get-Date).ToString("o")
        notes = ""
    }
}

$docRows | Export-Csv -LiteralPath (Join-Path $sourceRoot "api-doc-index.csv") -NoTypeInformation -Encoding utf8

$csvHeaders = @{
    "command-catalog.csv" = "command_id,api_profile_id,document_id,doc_location,raw_command,transport,scope,classification,scan_tier,cost_class,applicability,parameters,parameter_strategy,response_fields,pagination,mutating,requires_approval,notes"
    "device-inventory.csv" = "device_id,parent_device_id,cohort_id,api_profile_id,capability_signature,ip_or_endpoint,model,serial,firmware,online_status,first_seen,last_seen,discovery_command,discovery_evidence,scan_status,notes"
    "progress-ledger.csv" = "record_id,scan_mode,scan_tier,cohort_id,selection_reason,device_id,command_id,parameter_key,status,attempt,started_at,completed_at,raw_path,result_summary,error,doc_reference"
    "coverage-audit.csv" = "scan_mode,device_id,command_id,parameter_key,expected_fields,observed_fields,missing_fields,conditional_fields,redacted_fields,extra_fields,coverage_status,evidence_path,updated_at"
    "user-actions.csv" = "sequence,timestamp_or_order,actor,action_type,target_device,target_port_or_menu,before_state,after_state,result,reverted,evidence_path,notes"
}
foreach ($entry in $csvHeaders.GetEnumerator()) {
    Set-Content -LiteralPath (Join-Path $resolvedCaseRoot $entry.Key) -Value $entry.Value -Encoding utf8
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $skillRoot "assets"
$templateMap = @{
    "intake.template.md" = "intake.md"
    "classification.template.md" = "classification.md"
    "findings.template.md" = "findings.md"
    "checkpoint-log.template.md" = "checkpoint-log.md"
    "session-handoff.template.md" = "session-handoff.md"
    "final-report.template.md" = "final-report.md"
}
foreach ($entry in $templateMap.GetEnumerator()) {
    Copy-Item -LiteralPath (Join-Path $assetRoot $entry.Key) -Destination (Join-Path $resolvedCaseRoot $entry.Value)
}

$now = (Get-Date).ToString("o")
$nextAction = switch ($ScanMode) {
    "triage" { "Complete intake and user action history, make a provisional classification, then verify API documents, scope, endpoint, and access" }
    "deep" { "Complete intake and user action history, make a provisional classification, then define the fault domain and its minimum sufficient command set" }
    "audit" { "Complete intake and user action history, make a provisional classification, then verify prerequisites and build the complete command catalog" }
}
$checkpoint = [ordered]@{
    schema_version = 4
    case_id = $CaseId
    case_root = $resolvedCaseRoot
    session_scope = "current_session_only"
    session_nonce = $SessionNonce
    scan_mode = $ScanMode
    status = "initialized"
    intake_status = "pending"
    intake_completed_at = $null
    classification_status = "not_started"
    primary_category = $null
    secondary_categories = @()
    classification_confidence = $null
    classification_updated_at = $null
    created_at = $now
    updated_at = $now
    document_count = $docRows.Count
    command_count = 0
    cohort_count = 0
    online_device_count = 0
    matrix_row_count = 0
    completed_count = 0
    failed_count = 0
    blocked_count = 0
    core_completed_count = 0
    diagnostic_completed_count = 0
    audit_completed_count = 0
    last_completed_record = $null
    next_action = $nextAction
}
$checkpoint | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $resolvedCaseRoot "checkpoint.json") -Encoding utf8

$handoffPath = Join-Path $resolvedCaseRoot "session-handoff.md"
$handoff = Get-Content -Raw -LiteralPath $handoffPath
$handoff = $handoff.Replace("{{SESSION_NONCE}}", $SessionNonce).Replace("{{SCAN_MODE}}", $ScanMode).Replace("{{NEXT_ACTION}}", $nextAction).Replace("{{UPDATED_AT}}", $now)
Set-Content -LiteralPath $handoffPath -Value $handoff -Encoding utf8

Add-Content -LiteralPath (Join-Path $resolvedCaseRoot "checkpoint-log.md") -Value "`n- $now — Case initialized as ``$CaseId`` in ``$ScanMode`` mode with $($docRows.Count) API document source(s)."

Write-Output ([pscustomobject]@{
    CaseRoot = $resolvedCaseRoot
    SessionNonce = $SessionNonce
    ScanMode = $ScanMode
})
