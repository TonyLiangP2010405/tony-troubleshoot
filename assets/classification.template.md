# Problem classification

Use category IDs from `references/troubleshooting-taxonomy.md` in the Skill. Classify only after intake, customer-file review, and official-research gates are satisfied.

## Current classification

- Classified at:
- Status: **not_started** (`provisional`, `confirmed`, or `inconclusive`)
- Primary category:
- Secondary categories:
- Confidence: (`low`, `medium`, or `high`)
- Diagnostic dimensions: (`visible_parameter_state`, `firmware_exposed_parameter_state`, `volatile_runtime_state`, `persistent_internal_state`, `external_path`, or other evidence-based dimensions)

## Basis

- User symptom evidence:
- Relevant entries from `user-actions.csv`:
- Device/log/measurement evidence:
- Contradicting evidence:
- Important alternatives excluded:
- Remaining information gaps:
- Smallest next verification:
- Baseline used and whether it is truly pre-fault or only session-start:

## Causality caution

State whether an earlier user action is merely temporally related, a test result, or a supported cause. Do not turn sequence into causality without repeatability and mechanism evidence.

## Candidate-problem multi-selection

Complete this only after all currently received materials have passed their role-specific review and the provisional classification exists.

- Candidate list presented at:
- Every unresolved, evidence-based candidate has `customer_visible=yes`: **no**
- Suggested default IDs and reason:
- Customer's exact multi-selection or delegation words:
- Selected IDs in customer order:
- Unselected IDs retained as active backlog:
- Selection status: **not_started** (`pending_user`, `selected`, `customer_deferred`, or `blocked`)
- Selection is priority only and not write authorization: **acknowledged**
- `checkpoint.json` updated before any execution rows were created: **no**

## Revision history

Append each category/status/confidence change with timestamp, previous value, new value, and evidence-based reason. Do not erase earlier classifications.
