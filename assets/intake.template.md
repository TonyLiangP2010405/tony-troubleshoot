# Diagnostic intake

## Completion gate

- Intake status: **pending**
- Record `complete` only after every required item below has an answer or is explicitly marked **unknown / uncertain / not remembered**.
- Ask one focused follow-up for any high-impact ambiguity; do not block indefinitely on unknowable details.

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

## Explicit unknowns and contradictions

- Unknowns:
- Conflicting recollections or evidence:
- Follow-up asked and response:

## Intake completion

- Completed at:
- Completed by:
- High-impact unknowns carried forward:
- `checkpoint.json` updated to `intake_status=complete`: **no**
