# Diagnostic intake

## Completion gate

- Intake status: **pending**
- Record `complete` only after every required item below has an answer or is explicitly marked **unknown / uncertain / not remembered**.
- Ask one focused follow-up for any high-impact ambiguity; do not block indefinitely on unknowable details.
- Before completion, ask the open-ended additional-files question below once. A clear answer of **none** satisfies this gate.

## Symptom in the user's own words

- What is visible/audible/not working:
- First noticed (timestamp or relative order):
- Continuous or intermittent:
- Still reproducible now:
- Affected and unaffected devices/rooms/ports:
- Last known-good state:

## Current environment and topology

- Source(s):
- TX / RX / controller:
- Display / audio endpoint:
- Switch / VLAN / network path:
- Cable path and port labels:
- Model and firmware/API versions:
- Recent environmental events (power, lightning, construction, heat, network change):

## What the user already did

The ordered source of truth is `user-actions.csv`. Record every known click, setting change, cable move/reseat/swap/replacement, power cycle, restart/reset, firmware/config change, source/display change, and network change. For each action capture its target, before/after state, observed result, whether it was reverted, and evidence.

Do not equate an action with a cause. Do not ask the user to repeat a completed step with a conclusive result unless the test conditions will differ; explain the changed condition first.

## Evidence already available

- Screenshots/photos:
- Logs/exported configuration:
- Indicator lights/error messages:
- Measurements:
- Every received file has been added to `source/customer-file-index.csv`: **no**

## Additional diagnostic files

After requesting the expected evidence, ask: **“Apart from the items already mentioned, do you have any other files or materials that might help diagnose the problem?”** Examples may include configuration exports, complete logs, screenshots/screen recordings, topology diagrams, switch configuration, event timestamps, firmware details, packet captures, or third-party device reports; do not limit the customer to this list.

- Question asked: **no**
- Customer response: (`provided`, `none`, `unknown`, or `will_provide_later`)
- Additional file/material inventory and why each may be relevant:
- Files promised later and expected time:
- Customer reminded to remove credentials, tokens, private keys, session cookies, and unrelated personal information: **no**
- Redactions or access limitations:
- Customer-file review status after intake: **pending** (`none_provided` only when no files were received)

## Explicit unknowns and contradictions

- Unknowns:
- Conflicting recollections or evidence:
- Follow-up asked and response:

## Intake completion

- Completed at:
- Completed by:
- High-impact unknowns carried forward:
- Additional-files question completed: **no**
- `checkpoint.json` updated to `intake_status=complete`: **no**
