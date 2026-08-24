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

$preparedDocuments = @()
foreach ($document in $ApiDocument) {
    $uri = $null
    if ([System.Uri]::TryCreate($document, [System.UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @("http", "https")) {
        $preparedDocuments += [pscustomobject]@{
            source_type = "url"
            original_source = $document
            source_path = $null
        }
        continue
    }
    if (-not (Test-Path -LiteralPath $document -PathType Leaf)) {
        throw "API document is neither an existing file nor an HTTP(S) URL: $document"
    }
    $preparedDocuments += [pscustomobject]@{
        source_type = "local-file"
        original_source = (Resolve-Path -LiteralPath $document).Path
        source_path = (Resolve-Path -LiteralPath $document).Path
    }
}

if (Test-Path -LiteralPath $resolvedCaseRoot) {
    $caseRootItem = Get-Item -LiteralPath $resolvedCaseRoot -Force
    if (($caseRootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "CaseRoot cannot be a reparse point: $resolvedCaseRoot"
    }
    $existingItems = @(Get-ChildItem -LiteralPath $resolvedCaseRoot -Force)
    if ($existingItems.Count -gt 0) {
        throw "CaseRoot already exists and is not empty: $resolvedCaseRoot"
    }
}

$caseParent = Split-Path -Parent $resolvedCaseRoot
if (-not (Test-Path -LiteralPath $caseParent -PathType Container)) {
    New-Item -ItemType Directory -Path $caseParent -Force | Out-Null
}
$stagingRoot = $resolvedCaseRoot + ".initializing-" + [guid]::NewGuid().ToString("N")
New-Item -ItemType Directory -Path $stagingRoot | Out-Null
$workingCaseRoot = $stagingRoot

try {
$sourceRoot = Join-Path $workingCaseRoot "source"
$apiDocRoot = Join-Path $sourceRoot "api-docs"
$customerFileRoot = Join-Path $sourceRoot "customer-files"
$baselineRoot = Join-Path $sourceRoot "baselines"
$rawRoot = Join-Path $workingCaseRoot "raw"
New-Item -ItemType Directory -Path $sourceRoot, $apiDocRoot, $customerFileRoot, $baselineRoot, $rawRoot | Out-Null

$docRows = @()
$docOrdinal = 0
foreach ($document in $preparedDocuments) {
    $docOrdinal += 1
    if ($document.source_type -eq "url") {
        $docRows += [pscustomobject]@{
            document_id = "DOC-{0:D3}" -f $docOrdinal
            source_type = "url"
            original_source = $document.original_source
            preserved_path = ""
            sha256 = ""
            model_series = ""
            firmware_api_version = ""
            indexed_at = (Get-Date).ToString("o")
            notes = "URL recorded; preserve a local copy before collection"
        }
        continue
    }

    $sourcePath = $document.source_path
    $destinationName = "{0:D3}-{1}" -f $docOrdinal, [System.IO.Path]::GetFileName($sourcePath)
    $destinationPath = Join-Path $apiDocRoot $destinationName
    $finalDestinationPath = Join-Path (Join-Path $resolvedCaseRoot "source\api-docs") $destinationName
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
    $hash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash.ToLowerInvariant()

    $docRows += [pscustomobject]@{
        document_id = "DOC-{0:D3}" -f $docOrdinal
        source_type = "local-file"
        original_source = $sourcePath
        preserved_path = $finalDestinationPath
        sha256 = $hash
        model_series = ""
        firmware_api_version = ""
        indexed_at = (Get-Date).ToString("o")
        notes = ""
    }
}

$docRows | Export-Csv -LiteralPath (Join-Path $sourceRoot "api-doc-index.csv") -NoTypeInformation -Encoding utf8
Set-Content -LiteralPath (Join-Path $sourceRoot "customer-file-index.csv") -Value "file_id,original_name,preserved_path,sha256,file_type,size_bytes,received_at,customer_description,relevance,total_scope,reviewed_scope,review_status,unreadable_scope,evidence_locations,notes" -Encoding utf8
Set-Content -LiteralPath (Join-Path $workingCaseRoot "baseline-index.csv") -Value "baseline_id,baseline_type,captured_at,timezone,device_id,api_profile_id,model,firmware,scope,source,evidence_path,sha256,reliability,notes" -Encoding utf8
Set-Content -LiteralPath (Join-Path $workingCaseRoot "baseline-comparison.csv") -Value "comparison_id,device_id,baseline_id,current_capture_id,field_path,baseline_value,current_value,difference_status,diagnostic_significance,evidence_path,notes" -Encoding utf8

$csvHeaders = @{
    "command-catalog.csv" = "command_id,api_profile_id,document_id,doc_location,raw_command,transport,scope,classification,scan_tier,cost_class,applicability,parameters,parameter_strategy,response_fields,pagination,mutating,requires_approval,notes"
    "device-inventory.csv" = "device_id,parent_device_id,cohort_id,api_profile_id,capability_signature,ip_or_endpoint,model,serial,firmware,online_status,first_seen,last_seen,discovery_command,discovery_evidence,scan_status,notes"
    "progress-ledger.csv" = "record_id,scan_mode,scan_tier,cohort_id,selection_reason,device_id,command_id,parameter_key,status,attempt,started_at,completed_at,raw_path,result_summary,error,doc_reference"
    "coverage-audit.csv" = "scan_mode,coverage_level,device_id,command_id,parameter_key,expected_fields,observed_fields,missing_fields,conditional_fields,redacted_fields,extra_fields,coverage_status,evidence_path,updated_at"
    "user-actions.csv" = "sequence,timestamp_or_order,actor,action_type,target_device,target_port_or_menu,before_state,after_state,result,reverted,evidence_path,notes"
}
foreach ($entry in $csvHeaders.GetEnumerator()) {
    Set-Content -LiteralPath (Join-Path $workingCaseRoot $entry.Key) -Value $entry.Value -Encoding utf8
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $skillRoot "assets"
$templateMap = @{
    "intake.template.md" = "intake.md"
    "customer-file-review.template.md" = "customer-file-review.md"
    "official-research.template.md" = "wyrestorm-official-research.md"
    "classification.template.md" = "classification.md"
    "findings.template.md" = "findings.md"
    "checkpoint-log.template.md" = "checkpoint-log.md"
    "session-handoff.template.md" = "session-handoff.md"
    "final-report.template.md" = "final-report.md"
}
foreach ($entry in $templateMap.GetEnumerator()) {
    Copy-Item -LiteralPath (Join-Path $assetRoot $entry.Key) -Destination (Join-Path $workingCaseRoot $entry.Value)
}

$now = (Get-Date).ToString("o")
$nextAction = switch ($ScanMode) {
    "triage" { "Complete intake and user action history, fully review all customer-provided files, complete targeted WyreStorm official research, make a provisional classification, then verify API documents, scope, endpoint, and access" }
    "deep" { "Complete intake and user action history, fully review all customer-provided files, complete targeted WyreStorm official research, make a provisional classification, then define the fault domain and its minimum sufficient command set" }
    "audit" { "Complete intake and user action history, fully review all customer-provided files, complete targeted WyreStorm official research, make a provisional classification, then verify prerequisites and build the complete command catalog" }
}
$checkpoint = [ordered]@{
    schema_version = 7
    case_id = $CaseId
    case_root = $resolvedCaseRoot
    session_scope = "current_session_only"
    session_nonce = $SessionNonce
    scan_mode = $ScanMode
    status = "initialized"
    intake_status = "pending"
    intake_completed_at = $null
    customer_file_review_status = "pending"
    customer_file_review_updated_at = $null
    official_research_status = "not_started"
    official_research_updated_at = $null
    classification_status = "not_started"
    primary_category = $null
    secondary_categories = @()
    classification_confidence = $null
    classification_updated_at = $null
    created_at = $now
    updated_at = $now
    document_count = $docRows.Count
    baseline_count = 0
    baseline_comparison_count = 0
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
$checkpoint | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $workingCaseRoot "checkpoint.json") -Encoding utf8

$handoffPath = Join-Path $workingCaseRoot "session-handoff.md"
$handoff = Get-Content -Raw -LiteralPath $handoffPath
$handoff = $handoff.Replace("{{SESSION_NONCE}}", $SessionNonce).Replace("{{SCAN_MODE}}", $ScanMode).Replace("{{NEXT_ACTION}}", $nextAction).Replace("{{UPDATED_AT}}", $now)
Set-Content -LiteralPath $handoffPath -Value $handoff -Encoding utf8

Add-Content -LiteralPath (Join-Path $workingCaseRoot "checkpoint-log.md") -Value "`n- $now — Case initialized as ``$CaseId`` in ``$ScanMode`` mode with $($docRows.Count) API document source(s)."

if (Test-Path -LiteralPath $resolvedCaseRoot) {
    $existingItems = @(Get-ChildItem -LiteralPath $resolvedCaseRoot -Force)
    if ($existingItems.Count -gt 0) {
        throw "CaseRoot changed during initialization and is no longer empty: $resolvedCaseRoot"
    }
    Remove-Item -LiteralPath $resolvedCaseRoot -Force
}
Move-Item -LiteralPath $stagingRoot -Destination $resolvedCaseRoot
} catch {
    if (Test-Path -LiteralPath $stagingRoot) {
        $resolvedStagingRoot = (Resolve-Path -LiteralPath $stagingRoot).Path
        $expectedStagingPrefix = $resolvedCaseRoot + ".initializing-"
        if (-not $resolvedStagingRoot.StartsWith($expectedStagingPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Initialization failed and the staging path was unexpected; refusing cleanup: $resolvedStagingRoot"
        }
        Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
    }
    throw
}

Write-Output ([pscustomobject]@{
    CaseRoot = $resolvedCaseRoot
    SessionNonce = $SessionNonce
    ScanMode = $ScanMode
})
