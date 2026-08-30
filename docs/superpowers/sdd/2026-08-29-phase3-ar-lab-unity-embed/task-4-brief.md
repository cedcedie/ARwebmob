# Task 4: Unity generic hotspot/legend scaffold

> ⚠️ Reconstructed after the fact (see Task 2 brief). Target file lives
> outside this git repo, dated from the session record only.

**Files (outside this repo, no automated tests):**
`C:\Users\cedri\VuforiaAR\Assets\Scripts\ModelHotspotLegend.cs` (new).

**Dispatched as:** implementer subagent (shell-executing, native file
edit), `claude-sonnet-5-thinking-medium`.

## Ask

Build a generic, reusable multi-part-model hotspot/legend scaffold — not
wired to any specific model yet, per the user's explicit decision to build
the capability without authoring content for it (23 working Vuforia
markers exist, each showing one 3D model; no model currently has
authored hotspot data, and none needed to for this task). A
`HandleHotspotTap(string partName)` entry point that looks up a
`Hotspot[]` array (serialized in the Inspector, empty by default) by
`partName` and sends a `hotspotTapped` bridge message with `partName` and
a human-readable `label`.

## Fix applied during the same session (not a separate dispatch)

Initial draft identified the model via a private `int modelIndex` field —
the same ambiguous concept just proven broken in Task 2/6. Since nothing
consumes this file yet (scaffold-only, unused), the ambiguity had no
functional impact, but rather than seed the same bad pattern into new
code, it was corrected inline before considering the task done:
`modelIndex` removed, replaced with an `ObserverBehaviour` reference
fetched via `GetComponentInParent<ObserverBehaviour>()` in `Awake()` —
`GetComponentInParent` (not `GetComponent`) because this component is
expected to live on/under a model root, itself a child of the marker/
target GameObject that actually carries `ObserverBehaviour`. Bridge
message changed to carry `trackableName` (from `_observer.TargetName`)
instead of `modelIndex`, with a null-observer guard (no-op if absent) and
the same `EscapeForJson` helper pattern as Task 3.
