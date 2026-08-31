# SDD ledger — plan: docs/superpowers/plans/2026-08-31-phase5-item-analysis-ppt-pipeline.md

## Setup

- Working directly in `worktree-phase1-scaffold-core-auth` (the single active
  development branch, per this repo's own `CLAUDE.md` convention — no
  separate short-lived worktree for this phase; Phase 4's worktree was
  merged in already and this repo currently runs all phases on one branch).
- Baseline: `flutter test` 197/197 passing before any Phase 5 task starts.
- Spec: `docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
  Section 6 (Phase 5) + Section 7 (Q1/Q2, both confirmed 2026-08-31);
  `PROJECT_FLOW.md` Part 7.5, Part 8. Plan's Global Constraints read and
  understood, including the Blaze-plan prerequisite for Task 8.

## Pre-flight conflict scan

I authored this plan myself this session (brainstorming → spec → plan, all
in this same session), so the scan below is a self-check against what I
wrote, not a review of someone else's plan.

| Pair / Task | Produces → Consumes | Finding |
|---|---|---|
| Task 1 → Task 2 | `computeItemAnalysis`/`QuestionItemAnalysis` → `buildItemAnalysisViewModel` | Clean — signatures match exactly. |
| Task 2 → Task 3 | Task 3 replaces Task 2's `buildItemAnalysisViewModel` (adds required `quizRepository` param, `async*`) | Real signature change, already resolved in-plan: Task 3 Step 2 explicitly instructs updating Task 2's own test file's call sites to add `quizRepository: QuizRepository(firestore: firestore)`. Not a silent gap. |
| Task 4 → Task 6 | `TeacherLesson.contentImageUrls`/`contentStatus` → lesson_form.dart's submit logic | Clean, straightforward field consumption. |
| Task 5 → Task 6 | `LessonContentUploadService`/`FirebaseStorageUploader` → lesson_form.dart | Clean — Task 6 explicitly updated to the narrow-interface constructor shape (`uploader:` not `storage:`) during this plan's self-review, so no stale reference. |
| Task 4/Task 7 | `TeacherLesson` gains the two fields (Task 4); Task 7 separately notes `Lesson` (not `TeacherLesson`) and `LessonRepository._toLesson` also need the same two fields added, since `ArLabViewModel` is built from the merged `Lesson`, not the raw `TeacherLesson` | Real, correctly flagged in Task 7's own text as in-scope work for that task, not deferred/silent. |
| Task 6 vs Task 7 | Both modify `pubspec.yaml` | Additive only (different dependency lines: `file_picker`/`firebase_storage` in Task 5, `photo_view` in Task 7) — no line-level conflict. |
| Task 8 | Separate Node.js codebase (`functions/`), no Dart file overlap with any other task | Clean, fully independent; can be dispatched in any order relative to Tasks 1-7, kept last per the plan's own sequencing for narrative clarity only. |
| Task 3 internal | `_QuestionAnalysisCard`'s field types | Fixed during this plan's own self-review (was `dynamic`, now `BuiltInQuestion`/`QuestionItemAnalysis` with real imports) — no placeholder remains. |
| Task 5 internal | Storage-testing approach | Fixed during self-review — replaced a hedged `implements dynamic`/`noSuchMethod` stub with a real, narrow `StorageUploader` interface `LessonContentUploadService` owns itself, trivially fakeable for real. |

**No rulings needed pre-dispatch** — the scan surfaced only already-resolved,
in-plan-text items (each task explicitly says what it needs to update in an
earlier task), not unresolved conflicts. Proceeding to Task 1.

## Task progress

Task 1: implementer (haiku) hit a session-wide rate limit right after
confirming tests passed but before committing — resumed the same agent
once the limit cleared to finish committing/reporting. No rework needed,
files on disk already matched the brief.

Task 1: complete (commits 9ad7f43..4258f9e, review clean). Spec ✅, 0
issues. 201/201 full suite.

Task 2: complete (commits 4258f9e..6d80ebd, review clean). Spec ✅, 0
issues. 203/203 full suite.

Task 3: implementer found and fixed a real bug in the plan's own sample
code — `BarRodData` doesn't exist in fl_chart 0.69.x (real class is
`BarChartRodData`), verified against the installed package source, not
guessed. Also extended beyond the literal Step 7 wording: wired a real
`.family` provider override + go_router route for ItemAnalysisScreen
(without which the navigation link would've thrown UnimplementedError),
and fixed a RenderFlex overflow the new Actions-column icon caused in 2
existing tests. 206/206 full suite.

Task 3: complete (commits 6d80ebd..a31ec98, review clean). Spec ✅, 0
Critical/Important — all 3 deviations independently verified correct
(fl_chart class name, wiring necessity, layout fix). 2 Minor deferred:
(a) discrimination-index bar chart uses .abs() so color encodes sign but
bar height doesn't, inherited from the plan's own sample code; (b) route's
quizTitle extra defaults to quizId if ever passed a non-String, defensive
but silent.

Task 4: complete (commits a31ec98..d750d1a, review clean). Spec ✅, 0
Critical/Important. 1 trivial Minor: duplicated comment in generated
freezed.dart (build_runner artifact, self-regenerates, not worth touching).
208/208 full suite.

Task 5: complete (commits d750d1a..410cd74, review clean). Spec ✅, 0
Critical/Important. 1 Minor deferred: no test for filenames with unusual
characters (spaces/slashes could create unintended nested paths) — not
required by the brief, caller-validation territory. 209/209 full suite.

Task 6: implementer found and fixed a real bug in the plan's own sample
code — the brief's `_pickAndUploadContent()` called
`FilePicker.platform.pickFiles()` unconditionally, which would've bypassed
`uploadContentOverride` in tests entirely (no platform channel handler →
null result → silent early return, override never invoked). Fixed by
skipping the real picker call when the override is set. Also enlarged the
test viewport to fix an overflow the new upload button caused at the
default 800x600 test surface.

Task 6: complete (commits 410cd74..d290918, review APPROVE). Spec ✅, 0
Critical/Important — both deviations (pickFiles-bypass fix, viewport
enlargement) independently verified correct and necessary. 2 Minor: (a)
self-report misattributed the viewport-pattern precedent to the wrong test
file (non-functional); (b) `result?.files.single` would throw StateError
on a multi-file/zero-file picker result, inherited verbatim from the
brief. 210/210 full suite. `flutter analyze`: 36 issues, only 2 new (both
harmless unused-import warnings carried over verbatim from the brief).

Task 7: implementer found and fixed two real bugs in the plan's own
sample code — (a) a bare `NetworkImage` with no `errorBuilder` threw
`NetworkImageLoadException` uncaught on any load failure (test env and
real network hiccups/expired signed URLs alike), fixed with a genuine
photo_view 0.15.0 `errorBuilder` API (verified against installed package
source); (b) the sample omitted `dispose()` on the `PageController`, a
real resource leak given `ContentViewer` mounts/unmounts per lesson
navigation. Also correctly extended `Lesson`/`LessonRepository._toLesson`/
`ArLabViewModel` with `contentImageUrls`/`contentStatus`, following the
existing `hasAR`/`arPayload` pattern exactly (verified, not just claimed).

Task 7: complete (commits d290918..e26b5f0, review APPROVE). Spec ✅, 0
Critical/Important, 0 Minor — all four self-reported deviations
independently verified correct (errorBuilder is a real supported API,
dispose is correct with no double-dispose risk, field additions genuinely
match the existing pattern, built-in curriculum lessons confirmed to never
crash since they're constructed directly, bypassing `_toLesson`).
214/214 full suite. `flutter analyze`: 0 new issues in touched files.

Task 8: user gated this task explicitly — write and commit real Cloud
Function code (functions/), but do NOT actually deploy or touch billing;
defer Blaze-plan + deploy + verification to MANUAL_STEPS.md. Implementer
found a real bug in the brief's own sample Dockerfile: it installs only
`libreoffice-impress`, but the code shells out to `pdftoppm`, which ships
in the separate `poppler-utils` package — without it every conversion
would ENOENT. Fixed by adding `poppler-utils`, reviewer independently
confirmed this is technically correct (pdftoppm is genuinely not part of
libreoffice-impress). Complete (commits e26b5f0..1b1875d, review CHANGES
NEEDED — documentation-only, no code changes). Spec ✅ for the code itself
(byte-for-byte match of the brief's logic, verified line-by-line by
reviewer). Reviewer found 2 real gaps in MANUAL_STEPS.md §6 that the
implementer's own concerns list had flagged but never actually written
into the doc: (a) getSignedUrl() needs the Cloud Run service account to
hold Service Account Token Creator (signBlob permission) or every
conversion will fail at that call even after a successful deploy; (b)
firebase.json has no functions source entry yet, so `firebase deploy
--only functions` won't find anything without one. Fixed directly
(commit b39a087, doc-only, no re-review needed for a doc-only fix) —
MANUAL_STEPS.md §6 now has 6.2/6.3 covering both, renumbering 6.2-6.4 to
6.4-6.6. Minor issues (all deferred, none blocking): no cleanup of
orphaned slide PNGs on PPTX re-upload with fewer slides (inherited from
the brief); 8 moderate npm audit vulnerabilities in the dependency tree
(unmentioned, not blocking); no Storage security rules for `lessons/`
anywhere in the repo (pre-existing gap, out of scope for this task).

Task 9: complete (commit 90595ee). Full suite: 214/214 passing (personally
run). `flutter analyze`: 36 issues, exactly matching the established
baseline — no new issues. `MANUAL_STEPS.md` confirmed current (§6
finalized with the Task 8 review's IAM/firebase.json fixes). Checkpoint
committed.

All 9 Phase 5 tasks complete. Next: final whole-branch review covering
the entire Phase 5 diff, then `superpowers:finishing-a-development-branch`.

## Final whole-branch review (Opus, diff 041b703..90595ee)

CHANGES NEEDED — 2 Critical + 3 Important findings:

1. CRITICAL — lesson_form.dart: `_pickAndUploadContent` and `_handleSubmit`
   each independently computed `widget.initial?.id ??
   'teacher-${DateTime.now()...}'` for a brand-new lesson at different
   wall-clock moments, so the Storage upload and the Firestore doc landed
   under two different ids — the Cloud Function's later Firestore update
   then targeted a nonexistent doc, leaving the lesson stuck "processing"
   forever.
2. CRITICAL — item analysis for teacher-linked quizzes always reported "no
   attempts yet": student attempts are recorded under the synthesized
   builtin id (`builtinQuizId(lessonId, phase)`) even when the questions
   came from a linked teacher-authored quiz, but item analysis filtered by
   the authored quiz's own Firestore doc id when opened from
   quizzes_screen.dart. The ids never matched.
3. IMPORTANT — content_viewer.dart fed every content URL into
   `NetworkImage`/`PhotoViewGallery` regardless of format. A PDF upload
   sets `contentStatus: 'ready'` immediately with a single non-image URL,
   so students saw a broken-image icon.
4. IMPORTANT — functions/Dockerfile is likely ignored by `firebase deploy
   --only functions` (Gen2 functions build via Cloud Buildpacks, not a
   custom Dockerfile) — deployed function may lack soffice/pdftoppm
   entirely. User decision: defer as documentation-only (flag in
   MANUAL_STEPS.md §6, no code restructure) rather than fix now.
5. IMPORTANT — save-after-conversion race: if the Cloud Function finishes
   converting a PPTX before the teacher clicks Save, the form's stale
   local state (`_uploadedContentUrl`/`'processing'`) could get submitted
   via `LessonRepository.updateLesson`'s full `.set()`, permanently
   clobbering the real conversion result.

## Fix wave (Sonnet implementer, one commit per fix)

An initial dispatch was interrupted mid-task by a session-wide Sonnet rate
limit (after wiring `refetchLesson` through `lessons_screen.dart` but
before adding the corresponding `LessonForm` parameter or committing
anything). Verified each already-written file against its finding by
reading the diffs directly, found the `LessonForm.refetchLesson` parameter
and its `_handleSubmit` usage genuinely missing (would not have compiled),
completed that piece plus its regression test, then committed:

- `ca8d070` — Fix 1 (lesson id computed once in `initState`, reused by
  upload and submit) + Fix 5 (`LessonRepository.fetchLessonById` wired
  through `lessons_providers.dart`/`lessons_screen.dart` to
  `LessonForm.refetchLesson`, checked in `_handleSubmit` before
  overwriting a possibly-since-converted lesson doc).
- `878d3e2` — Fix 2 (`buildItemAnalysisViewModel` takes a
  `LessonRepository`, resolves a teacher-linked quiz id to
  `builtinQuizId(lesson.id, QuizPhase.post)` before filtering attempts).
- `fff6677` — Fix 3 (`ContentViewer` detects a single PDF URL and renders
  an external-open affordance via `url_launcher` instead of
  `NetworkImage`; `url_launcher` promoted to a direct pubspec dependency).
- `e3f47b2` — Fix 4 (doc-only: confirmed/committed the
  `MANUAL_STEPS.md` §6 Buildpacks-vs-Dockerfile warning; no code change).

Full suite: 218/218 passing (214 baseline + 4 new regression tests, one
per code fix). `flutter analyze`: 35 issues (established baseline was 36;
the one-issue delta is a pre-existing unused-import duplicate that the
fix wave's own edit to that test file incidentally removed — no new
issues introduced).

## Scoped re-review (Sonnet reviewer, diff 90595ee..e3f47b2 only)

**READY TO MERGE.** All 5 findings independently verified RESOLVED,
including tracing `router.dart` to confirm hardcoding `QuizPhase.post` in
the Fix 2 resolution is correct (linked quizzes are only wired to the
post-test phase), confirming `url_launcher` is a real direct dependency
(not just referenced), and confirming Fix 4 touched only
`MANUAL_STEPS.md`. Re-ran `flutter test` (218/218) and `flutter analyze`
(35 issues, no new ones vs baseline) independently as evidence.

## Phase 5 closure

`superpowers:finishing-a-development-branch` run. Per this repo's
CLAUDE.md (`main` is not used for development until the whole project is
done), user chose **Option 3: keep branch as-is** — no merge to `main`.
Branch `worktree-phase1-scaffold-core-auth` stays at commit `e3f47b2`,
worktree preserved at `.claude/worktrees/phase1-scaffold-core-auth/`, for
Phase 6 to build on.

**Phase 5: COMPLETE.**
