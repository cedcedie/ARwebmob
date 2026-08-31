# Project Handover — AR Science Explorer

This is the step-by-step walkthrough for handing this project from **you
(the developer, `cedcedie`)** to **the client**. Follow it in order — each
step says who does it and gives the exact terminal commands where there are
any, so anyone comfortable with a terminal can run their own steps without
needing you in the room.

For the flat checkbox reference of every manual item (Firebase config, Unity
export, known gaps), see `MANUAL_STEPS.md`. This document is the narrative
sequence that ties those together specifically for the handover moment.

---

## 0. Where things stand right now

- **Code**: all 5 phases (foundation, student core, AR Lab, Teacher Web,
  analytics/PPT pipeline) are merged onto `main` — this is the only branch,
  no worktrees remain.
- **Tests**: 264/264 passing (`flutter test` from the repo root), including
  a dedicated `test/integration/` suite that exercises real teacher→student
  flows (access codes, quiz retake rules, item analysis, lesson content
  delivery) against a shared fake Firestore backend.
- **Static analysis**: `flutter analyze` holds at 25 issues, all
  warnings/info-level (no errors) — style lints and one pre-existing
  deprecated-API warning outside this project's touched scope. Not a
  correctness concern.
- **Teacher Web UI/UX**: went through 7 rounds of adversarial critique
  (design + correctness reviewed independently each round), final combined
  score 33/40 — solidly in the "Good" band. Every P0/P1 finding across all
  7 rounds was closed; remaining open items are disclosed, minor polish.
- **Known, disclosed limitations** (not oversights — see §5 below):
  physical AR marker-scanning can't be automated in this dev environment
  (no device available), and the PPTX-upload Cloud Function is written but
  intentionally undeployed pending a client decision.

---

## 1. [DEV] Repo access

The repo stays **private** on GitHub — it carries internal build history
(`docs/superpowers/`) and architecture notes not meant for public
consumption.

1. If this repo isn't pushed to GitHub yet, create a private repo there and
   push `main`:
   ```powershell
   cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
   git remote add origin <your-private-repo-url>
   git push -u origin main
   ```
2. GitHub repo → Settings → Collaborators → add the client's GitHub account
   with at least **Write** access (or transfer the repo to their GitHub
   organization/account entirely, if that's the arrangement).
3. Confirm the client can clone it:
   ```powershell
   git clone <repo-url>
   ```

---

## 2. [DEV] Your own Firebase project stays yours

You already have a Firebase project (`ar-science-explorer`) under your own
account that this codebase has been developed and tested against. **That
project is not part of the handover** — it stays yours, for your own future
testing/reference if you want it. The client gets a completely separate,
brand-new project (§3). Nothing to do here except be aware of the split.

---

## 3. [CLIENT] Create their own Firebase project

1. Client goes to <https://console.firebase.google.com>, signs in with
   **their own** Google account (school/organization account recommended
   over a personal one, if they have one).
2. **Add project** → name it (e.g. `ar-science-explorer-<schoolname>`) →
   follow the prompts (Google Analytics is optional, not used by this app).
3. Stay on the free **Spark** plan for now — nothing in the core app
   (Auth, Firestore, Storage, Hosting) requires Blaze. Blaze is only needed
   if/when the PPTX Cloud Function gets deployed (§6 below).
4. Once the project exists, tell the developer its **Project ID** (shown on
   the Firebase Console's project overview) so step 4 can target it.

---

## 4. [DEV] Point the app at the client's new project

From the repo root, on a machine with the Firebase CLI installed and logged
into an account that has access to the client's new project (the client can
grant you temporary Editor access via Project Settings → Users and
permissions, or run this step themselves if they're comfortable with a
terminal):

```powershell
cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
dart pub global run flutterfire_cli:flutterfire configure
```

- Select the client's project (from §3) when prompted.
- Select platforms **Web** and **Android**.
- This overwrites `firebase_options.dart` and `google-services.json` to
  point at the client's project — commit that change:
  ```powershell
  git add lib/firebase_options.dart android/app/google-services.json
  git commit -m "chore: point Firebase config at client project"
  git push
  ```

---

## 5. [DEV or CLIENT] Firestore rules and auth accounts

Follow `MANUAL_STEPS.md` §2.2 and §2.3 exactly — create at least one teacher
account and a few student test accounts in the client's new project's
Firebase Authentication, and set the Firestore security rules from the table
there. This has to happen on the **client's** project specifically (rules
and auth users don't carry over from your dev project).

---

## 6. [CLIENT — decision required] PPTX vs PDF-only lesson content

The teacher lesson-upload form offers both PDF and PPTX as choices. PDF
works fully today, for free, no setup needed. PPTX requires deploying a
Cloud Function that needs the **Blaze** (pay-as-you-go) plan — realistically
**$0 actual cost** at small/pilot scale (Cloud Run/Functions/Build free
tiers comfortably cover a handful of students), but it does require
attaching a billing card to the Firebase project.

**Decide one:**

- **A. PDF-only for now** (recommended default) — do nothing further here.
  Teachers should be told/trained to upload lesson content as PDF, not
  PPTX, until/unless B is chosen later. No cost, no setup.
- **B. Deploy PPTX support** — client confirms they're okay attaching a
  billing card (expecting $0 real cost at this scale), then the developer
  follows `MANUAL_STEPS.md` §6 in full, including the one flagged
  architecture risk that needs verifying with a real test upload before
  trusting the pipeline.

Whichever is chosen, note it here for the record: ______________________

---

## 7. [DEV or CLIENT] Deploy Teacher Web (Firebase Hosting)

Free, no billing card, independent of the PPTX decision above. From the
repo root, once `flutterfire configure` (§4) has run against the client's
project:

1. Add a `"hosting"` block to the local `firebase.json` — see
   `MANUAL_STEPS.md` §7.5 for the exact JSON.
2. Build and deploy:
   ```powershell
   flutter build web --release
   firebase deploy --only hosting
   ```
3. Firebase prints a live `https://<project-id>.web.app` URL — that's the
   real link to give teachers, instead of running the app locally.
4. Re-run both commands any time you want a Teacher Web change to go live —
   there's no CI/auto-deploy wired up.

---

## 8. [DEV] Android app to the client

There's no Play Store release signing set up yet (not required for a
capstone demo). Two ways to get the app onto a device:

- **Sideload the debug APK** — build it once
  (`flutter build apk --debug` from the repo root — first build is slow,
  ~24 minutes, due to Unity's IL2CPP compile; cached rebuilds are ~2
  minutes), then hand over `build/app/outputs/flutter-apk/app-debug.apk`
  for the client to install directly (`adb install <path>`, or copy the
  file to the phone and open it — Android will prompt to allow installs
  from this source).
- **Play Store internal testing track** — only worth setting up if the
  client wants a more polished install flow (auto-updates, no "unknown
  sources" prompt); requires a release signing keystore (`MANUAL_STEPS.md`
  §7.2), which isn't done yet — flag to the client if this is wanted.

---

## 9. [DEV → CLIENT] Ownership transfer

Once the client's project is live, verified working (§4-§7 all confirmed),
and the client is comfortable:

1. Firebase Console (client's project) → Project Settings → Users and
   permissions → confirm the client's own account is already **Owner**
   (it should be, since they created it in §3) — nothing to transfer here,
   unlike a scenario where the dev created the project first.
2. If the developer was granted temporary access in step 4/5, the client
   removes that access once everything's confirmed working, or leaves it
   in place if ongoing support is part of the arrangement — client's call.
3. GitHub repo (§1): confirm the client's collaborator access is set the
   way they want it long-term (full transfer vs. ongoing collaborator).

---

## 10. Known, disclosed limitations — not oversights

Being upfront about what this handover does **not** include, and why:

1. **Physical AR marker-scanning on a real device was never automated.**
   This dev environment has no Android device or emulator available, so
   the Scan → camera → marker-detection → Flutter overlay flow
   (`MANUAL_STEPS.md` §4) has to be walked through by hand, once, by
   whoever has a physical phone. Everything else about the AR flow (data
   wiring, marker-to-model mapping, the Read/Review phases, voice
   narration lifecycle) is covered by automated tests; only the actual
   camera+Vuforia detection loop on real hardware isn't.
2. **PPTX upload is undeployed by decision, not oversight** — see §6 above.
3. **No responsive/adaptive layout on Teacher Web** — it's a deliberate
   desktop/laptop-only design (documented in-code on `TeacherShell`), not
   built for tablets or narrow viewports. Revisit only if the client
   specifically needs tablet support later.
4. **No CI/CD** — deploys (Hosting, Functions) are manual commands, not
   triggered automatically by a push. Worth adding later if this becomes a
   longer-running project with frequent updates.

---

## 11. Where to go for more detail

- `MANUAL_STEPS.md` — the flat, checkbox reference for every manual item
  (Unity export steps, Firestore rules table, full Cloud Function
  deployment sequence).
- `docs/superpowers/NICE_TO_HAVES.md` — minor, deferred findings logged
  across all phases (mostly resolved; a few intentionally left for a future
  general-cleanup pass).
- `PROJECT_FLOW.md` — the original functional spec (curriculum, access-code
  rules, quiz retake rules) this app was built against.
- `docs/superpowers/sdd/` — full build-log/provenance for Phases 3-5
  (task briefs, review reports) if you want the detailed history of how
  something was built or decided.
