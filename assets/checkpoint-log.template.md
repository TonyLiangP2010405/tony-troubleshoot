# Checkpoint log

Temporary current-session log. Append one timestamped entry after intake completion, every classification revision, each device, pagination sequence, or bounded batch, and immediately after inventory/mode changes, retries, blockers, rate-limit events, and closure discovery passes. Do not rewrite earlier entries. Consolidate it into `resolution-summary.md` and delete it after confirmed resolution.
