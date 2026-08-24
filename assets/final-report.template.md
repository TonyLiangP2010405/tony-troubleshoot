# WyreStorm diagnostic report

Temporary current-session working report. It will be consolidated into `resolution-summary.md` and deleted after the customer explicitly confirms resolution.

## Outcome

Scan mode: **record from checkpoint.json**

Status: **not assessed**

For `triage` or `deep`, describe the selected scope and do not claim full API coverage. For `audit`, keep the result incomplete until the complete coverage audit passes.

## User symptom and actions already taken

Summarize the user's original symptom and the relevant ordered rows from `user-actions.csv`: clicks, setting changes with old/new values, cable moves/reseats/swaps/replacements and both endpoints, restarts/resets, firmware/config changes, results, and whether each change was reverted. Clearly separate temporal correlation from supported cause.

## Final problem classification

Report primary and secondary categories, `confirmed` or `inconclusive` status, confidence, supporting and contradicting evidence, excluded alternatives, and any change from the provisional intake classification.

## WyreStorm official research preflight

List only the official sources that materially affected this case. For each, record the exact URL, access time, applicable model/series and firmware/API version, confirmed fact, and diagnostic effect. If official research was unavailable, record the reason and which user-provided documents were used instead. Do not present inference as an official statement.

## Scope and collection window

Record mode, timezone, start/end timestamps, endpoints, in-scope models/firmware, API profiles/cohorts, document IDs and hashes, and redaction policy.

Also summarize any additional files the customer volunteered, how each influenced the diagnosis, any promised-but-unreceived material, and the sensitive-data redactions applied.

## Online device inventory

Summarize devices and link each item to discovery evidence.

## Findings

Summarize confirmed facts first, then interpretations, with raw evidence paths. For every deep-dive device, include the anomaly or symptom that selected it.

## Coverage proof

Report core/diagnostic/audit command counts, selected parameter rows, devices, pages/cursors, response fields, completions, failures, unsupported items, and blockers.

For `triage`, list the audit-tier areas intentionally not executed. For `deep`, state the fault-domain boundary. For `audit`, record the two final discovery passes and prove full command/parameter/field coverage.

## Unresolved gaps

List unavailable items and intentionally unscanned areas. In `audit`, any unresolved item keeps the overall status partial/incomplete.

## Current-session resume/audit instructions

Point to temporary evidence only for compacting or model switches within this same conversation. Do not instruct a future session to resume this case.
