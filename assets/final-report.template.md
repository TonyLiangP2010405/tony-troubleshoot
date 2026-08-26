# WyreStorm diagnostic report

Temporary current-session working report. It will be consolidated into `resolution-summary.md` and deleted after the customer explicitly confirms resolution.

## Outcome

Scan mode: **record from checkpoint.json**

Status: **not assessed**

For `triage` or `deep`, describe the selected scope and do not claim full API coverage. For `audit`, keep the result incomplete until the complete coverage audit passes.

## User symptom and actions already taken

Summarize the user's original symptom and the relevant ordered rows from `user-actions.csv`: clicks, setting changes with old/new values, cable moves/reseats/swaps/replacements and both endpoints, restarts/resets, firmware/config changes, results, and whether each change was reverted. Clearly separate temporal correlation from supported cause.

## Customer-provided file review

List every received file, its hash, total verifiable scope, scope actually inspected, review method, key facts with exact page/sheet/cell/line/timestamp/frame locations, contradictions, and unreadable or skipped portions. Explain how each relevant file affected the classification or diagnostic plan. Do not claim complete review when any high-impact content remains unreadable.

## Final problem classification

Report primary and secondary categories, `confirmed` or `inconclusive` status, confidence, supporting and contradicting evidence, excluded alternatives, and any change from the provisional intake classification.

## Product-context research preflight

List only the official sources that materially affected this case. For each, record the exact URL, access time, applicable model/series and firmware/API version, confirmed fact, and diagnostic effect. If official research was unavailable, record the reason and which local or user-provided documents were used instead. Do not present inference as an official statement.

Also list material local `$tony-skill` evidence with source file, locator, document nature, model/version applicability, and diagnostic effect. Keep local engineering/supplier evidence distinct from official confirmation.

## Command-source reconciliation

Summarize static API, local knowledge-base, and same-firmware Web UI command differences. For every firmware-only command used, record firmware/build, exact transport, passive UI call evidence, safety class, replay scope, response evidence, and that cross-transport compatibility was not inferred.

## Web UI session usage

List the relevant device pages the user opened and logged in to, the read-only consent and agent access mode, device-identity verification, session interruptions, and Web-only API calls. State that authentication secrets stayed inside the user's browser session and that no Web-only API was rerouted through Telnet/SSH.

## Scope and collection window

Record mode, timezone, start/end timestamps, endpoints, in-scope models/firmware, API profiles/cohorts, document IDs and hashes, and redaction policy.

Also summarize any additional files the customer volunteered, how each influenced the diagnosis, any promised-but-unreceived material, and the sensitive-data redactions applied.

## Online device inventory

Summarize devices and link each item to discovery evidence.

## Findings

Summarize confirmed facts first, then interpretations, with raw evidence paths. For every deep-dive device, include the anomaly or symptom that selected it.

Include the ranked hypothesis table with supported, weakened, rejected, confirmed, and blocked candidates. For `single_physical`, summarize each user-performed physical action followed by the analyst's read-only retest.

## Baseline and device intrinsic state

State which baselines were available and label each as known-good, pre-fault, session-start, post-action, or resolved. Report normalized differences and the limits of any zero-difference claim. If reboot or factory reset was used, record its authorization, exact scope, backup/recovery plan, result, and what the result does and does not prove.

## Coverage proof

Report core/diagnostic/audit command counts, selected parameter rows, devices, pages/cursors, response fields, completions, failures, unsupported items, and blockers. Separate lightweight essential-field checks from full field audits.

For `triage`, list the audit-tier areas intentionally not executed. For `deep`, state the fault-domain boundary. For `audit`, record the two final discovery passes and prove full command/parameter/field coverage.

## Unresolved gaps

List unavailable items and intentionally unscanned areas. In `audit`, any unresolved item keeps the overall status partial/incomplete.

## Current-session resume/audit instructions

Point to temporary evidence only for compacting or model switches within this same conversation. Do not instruct a future session to resume this case.
