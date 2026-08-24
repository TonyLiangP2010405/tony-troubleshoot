[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CaseRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SessionNonce,

    [Parameter(Mandatory = $true)]
    [switch]$CustomerConfirmed,

    [Parameter(Mandatory = $true)]
    [switch]$DeleteTemporaryArtifacts,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CustomerConfirmation,

    [string]$SummaryFileName = "resolution-summary.md"
)

$ErrorActionPreference = "Stop"

if (-not $CustomerConfirmed) {
    throw "CustomerConfirmed is required. Do not infer resolution from a temporary recovery."
}
if (-not $DeleteTemporaryArtifacts) {
    throw "DeleteTemporaryArtifacts is required because closure permanently removes temporary case files."
}
if ([System.IO.Path]::GetFileName($SummaryFileName) -ne $SummaryFileName) {
    throw "SummaryFileName must be a file name in the case root, not a path."
}

$resolvedCaseRoot = (Resolve-Path -LiteralPath $CaseRoot).Path
$resolvedCaseRoot = [System.IO.Path]::GetFullPath($resolvedCaseRoot).TrimEnd('\', '/')
$pathRoot = [System.IO.Path]::GetPathRoot($resolvedCaseRoot).TrimEnd('\', '/')
$userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile).TrimEnd('\', '/')
if ([string]::Equals($resolvedCaseRoot, $pathRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to close a filesystem root: $resolvedCaseRoot"
}
if ([string]::Equals($resolvedCaseRoot, $userProfile, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to close the user profile directory: $resolvedCaseRoot"
}

$caseRootItem = Get-Item -LiteralPath $resolvedCaseRoot -Force
if (($caseRootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Refusing to close a case root that is a reparse point: $resolvedCaseRoot"
}

$checkpointPath = Join-Path $resolvedCaseRoot "checkpoint.json"
if (-not (Test-Path -LiteralPath $checkpointPath -PathType Leaf)) {
    throw "checkpoint.json is required to verify the exact case root."
}
$checkpoint = Get-Content -Raw -LiteralPath $checkpointPath | ConvertFrom-Json
if (-not [string]::Equals([System.IO.Path]::GetFullPath([string]$checkpoint.case_root).TrimEnd('\', '/'), $resolvedCaseRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "checkpoint.json does not identify this exact CaseRoot."
}
if ($checkpoint.session_scope -ne "current_session_only") {
    throw "This case is not marked as current-session-only. Refusing automatic cleanup."
}
if (-not [string]::Equals([string]$checkpoint.session_nonce, $SessionNonce, [System.StringComparison]::Ordinal)) {
    throw "SessionNonce does not match this case. Refusing cross-session cleanup."
}

$summaryPath = Join-Path $resolvedCaseRoot $SummaryFileName
if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
    throw "Create the self-contained summary before cleanup: $summaryPath"
}
$summaryItem = Get-Item -LiteralPath $summaryPath -Force
if (($summaryItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "The retained summary cannot be a reparse point."
}
$summary = Get-Content -Raw -LiteralPath $summaryPath
if ($summary.Trim().Length -lt 300) {
    throw "The resolution summary is too short to preserve the diagnostic process."
}
$unfinishedMarkers = @("{{", "not assessed", "Describe the original symptom", "Summarize relevant devices", "State the confirmed root cause")
foreach ($marker in $unfinishedMarkers) {
    if ($summary.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "The resolution summary still contains an unfinished template marker: $marker"
    }
}

$closedAt = (Get-Date).ToString("o")
$closureMetadata = @"

## Closure metadata

- Customer confirmation: $CustomerConfirmation
- Closed at: $closedAt
- Session nonce: $SessionNonce
- Cleanup: all temporary case artifacts removed; this summary retained
"@
Add-Content -LiteralPath $summaryPath -Value $closureMetadata -Encoding utf8

$rootPrefix = $resolvedCaseRoot + [System.IO.Path]::DirectorySeparatorChar
$children = @(Get-ChildItem -LiteralPath $resolvedCaseRoot -Force)
$deleteTargets = @()
foreach ($child in $children) {
    if ([string]::Equals($child.FullName, $summaryPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    $childPath = [System.IO.Path]::GetFullPath($child.FullName)
    if (-not $childPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete a path outside CaseRoot: $childPath"
    }
    if (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Remove or inspect the reparse point manually before cleanup: $childPath"
    }
    $deleteTargets += $child
}

$deletedNames = @($deleteTargets | Select-Object -ExpandProperty Name)
foreach ($target in $deleteTargets) {
    Remove-Item -LiteralPath $target.FullName -Recurse -Force
}

$remaining = @(Get-ChildItem -LiteralPath $resolvedCaseRoot -Force)
if ($remaining.Count -ne 1 -or -not [string]::Equals($remaining[0].FullName, $summaryPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Cleanup verification failed; the case root does not contain only the retained summary."
}

Write-Output ([pscustomobject]@{
    RetainedSummary = $summaryPath
    DeletedItemCount = $deletedNames.Count
    DeletedItems = ($deletedNames -join ", ")
    RecoverableBySkill = $false
})
