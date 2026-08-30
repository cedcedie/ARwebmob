# Task 3: Unity C# bridge edit — marker found/lost → Flutter

> ⚠️ Reconstructed after the fact (see Task 2 brief for why). This task's
> target file lives outside this git repo
> (`C:\Users\cedri\VuforiaAR\Assets\Scripts\ARTargetVisibilityAndInteraction.cs`),
> so there is no commit to anchor this to — it's dated from the session
> record only.

**Files (outside this repo, no automated tests — Unity project, verified
manually by the user in-editor):**
`C:\Users\cedri\VuforiaAR\Assets\Scripts\ARTargetVisibilityAndInteraction.cs`.

**Dispatched as:** implementer subagent (shell-executing, native file
edit), `claude-sonnet-5-thinking-medium`. Confirmed before dispatch that
`C:\Users\cedri\VuforiaAR` is not a git repo, so the subagent was told not
to attempt a commit.

## Ask

Strip Unity's own on-screen title/description panel rendering
(`UIManager`/`InteractiveLabel`) from `HandleTargetFound`/
`HandleTargetLost` — Flutter now owns rendering that UI, per the user's
"Unity owns camera+model only" rule — and instead fire a bridge message to
Flutter on each event via `SendToFlutter.Send(...)`, a global,
auto-referenced class confirmed to need no `using`/assembly wiring.

Message shape (final, after the Task 2 trackable-name pivot):
```json
{"event":"markerFound","trackableName":"DemocritusAtomQ1W1"}
{"event":"markerLost","trackableName":"DemocritusAtomQ1W1"}
```
`trackableName` sourced from `Vuforia.ObserverBehaviour.TargetName` (cache
the component reference in `Awake()`, same pattern as the file's existing
cached-reference style). Confirmed via Vuforia's own
`DefaultObserverEventHandler.cs` source that `ObserverBehaviour` sits on
the same GameObject as `ImageTargetBehaviour` (the latter extends the
former), so `GetComponent<ObserverBehaviour>()` on the same GameObject
this script lives on is correct — no cross-GameObject lookup needed.
Added a private `EscapeForJson` helper since trackable names could
theoretically contain characters needing escaping (defensive, not
currently triggered by any real marker name).

Rotate/zoom gesture handling in the same file was explicitly left
untouched.
