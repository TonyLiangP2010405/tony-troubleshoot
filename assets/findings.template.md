# Findings

## User-reported symptom and prior actions

Summarize the symptom in the user's words. Reference the relevant ordered rows in `user-actions.csv`, including clicks, setting changes, cable handling, restarts, resets, firmware/config changes, their observed results, and whether they were reverted. Keep temporal relation separate from proven causality.

## Problem classification

Record the current primary and secondary categories, status, confidence, supporting evidence, contradictions, exclusions, and revision reason from `classification.md`.

## Ranked hypotheses

Summarize active rows from `hypothesis-ledger.csv`:

| Rank | Hypothesis | Category / dimension | Status | Supporting evidence | Contradicting evidence | Next smallest discriminator |
|---|---|---|---|---|---|---|
| 1 |  |  | active |  |  |  |

Update, weaken, reject, or confirm existing hypotheses after each physical-action/read-only-retest cycle; do not retain duplicate wording as separate candidates.

## Customer-file evidence

Summarize the complete customer-file inventory, verified review scope, key facts with exact locations, contradictions, unreadable portions, and how the files changed or constrained the diagnosis. Do not cite a search hit without its surrounding context.

## Web UI session and Web-only API evidence

Summarize which relevant pages the user opened and logged in to, whether the agent used an existing authenticated page or the user operated it, how device identity was verified, and every Web-only API used. Record same-origin/session/transport basis and redacted evidence; never include credentials, Cookie, authorization headers, CSRF tokens, or handshake secrets.

## Scan mode and selection rationale

Record the active mode and case shape. For `fleet`, include core sweep and cohorts. For `single_physical`, state why cohort/matrix work was skipped and summarize the user-action/read-only-retest cycles.

## Baseline and device-state comparison

Distinguish known-good/pre-fault evidence from the session-start snapshot. Summarize normalized differences and zero-difference results, external-path exclusions, reboot outcome, and any `persistent_internal_state` hypothesis. A successful factory reset supports an internal persistent-state relationship but does not alone prove physical storage corruption.

## Confirmed facts

Record evidence-backed facts with device ID, command ID, parameter key, timestamp, and raw evidence path.

## Diagnostic interpretations

Keep hypotheses separate from confirmed facts. State supporting and contradicting evidence. Do not treat a user action as the cause without repeatability and mechanism evidence.

## Unresolved information gaps

List every failed, unsupported, blocked, missing-field, permission, documentation, or reachability gap.
