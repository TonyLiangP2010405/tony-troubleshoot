# Customer-provided file review

- Status: **pending** (`complete`, `none_provided`, or `blocked` before initial classification)
- Review started at and timezone:
- Review completed/blocked at and timezone:
- Reviewer:

## File inventory and coverage

Create one subsection per row in `source/customer-file-index.csv`.

### FILE-001 — exact original name

- SHA-256 and preserved path:
- Customer description and expected relevance:
- Artifact role: (`reference_document`, `diagnostic_evidence`, or `mixed`)
- Format, size, and readable/encrypted/damaged status:
- Verifiable total scope (pages/slides/sheets/rows/time range/frames/internal files):
- Scope actually inspected and method used:
- Unreadable, skipped, truncated, filtered, or uncertain portions:
- Key facts with exact page/sheet/cell/line/timestamp/frame location:
- Contradictions and negative evidence:
- Diagnostic impact:
- Review status: **pending** (`reference_complete` is valid only for a reference document)

## Cross-file reconciliation

- Agreements between files and customer description:
- Conflicts, version differences, or timestamp/timezone issues:
- Follow-up questions and customer answers:
- Facts that changed the official-site research scope, classification, or command selection:

## Completion gate

- Every currently provided file is indexed with an artifact role: **no**
- Reference documents have applicability/relevant-section review; diagnostic evidence has full verifiable-scope review: **no**
- Key search/parse hits were read in context: **no**
- High-impact contradictions were resolved or carried as explicit blockers: **no**
- Newly added/replaced files reset this review to `pending`: **acknowledged**
- `checkpoint.json` updated to `customer_file_review_status=complete|none_provided|blocked`: **no**
