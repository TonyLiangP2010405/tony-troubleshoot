# Session handoff

- Session scope: current conversation only; never resume from a different session
- Session nonce: {{SESSION_NONCE}}
- Scan mode: {{SCAN_MODE}}
- Case status: initialized
- Intake status: pending
- Classification: not started
- Last completed record: none
- Next action: {{NEXT_ACTION}}
- Current inventory state: not started
- Current coverage state: not started
- Active blockers: endpoint, access, scope, and document applicability must be verified
- Resume instruction: only after the current conversation supplies the exact CaseRoot and matching session nonce, read this file, `checkpoint.json`, `intake.md`, `user-actions.csv`, `classification.md`, all other CSV ledgers, and the tail of `checkpoint-log.md`
- Last updated: {{UPDATED_AT}}
