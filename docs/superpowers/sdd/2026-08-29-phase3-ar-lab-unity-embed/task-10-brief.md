# Task 10: `ArLabScreen` — retire `LessonDetailScreen`, wire the route

**Files:**
- Create: `lib/features/student/ar_lab/ar_lab_screen.dart`
- Modify: `lib/features/student/app/router.dart`
- Modify: `lib/features/student/app/student_providers.dart`
- Delete: `lib/features/student/lesson_detail/lesson_detail_providers.dart`,
  `lib/features/student/lesson_detail/lesson_detail_screen.dart`,
  `test/features/student/lesson_detail/lesson_detail_screen_test.dart`
- Modify: `test/features/student/app/student_providers_test.dart` — replace
  the two `lessonDetailOverrideFor` test cases with `arLabOverrideFor`
  equivalents proving the same properties, don't just delete coverage.
- Test: `test/features/student/ar_lab/ar_lab_screen_test.dart`

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`, in worktree
`c:/Users/cedri/OneDrive/Documents/GitHub/ARwebmob/.claude/worktrees/phase1-scaffold-core-auth`,
branch `worktree-phase1-scaffold-core-auth`.

## Verified before dispatch (not assumed from the plan)

- `ArLabViewModel`'s real constructor (`lib/features/student/ar_lab/ar_lab_providers.dart`):
  `lessonId, title, summary, hasAR, markerIndex (int?), isRead, hasPreTest,
  postTestEligible, postTestReason (String?), studentId, accessCodeService,
  onMarkAsRead, onStartPreTest, onStartPostTest` — matches the plan's test
  sample exactly. `buildArLabViewModel(...)` signature also confirmed
  matching the plan's Step 5 sample (including `preTestLessonIds`).
- `ScanTab({vm, voiceOverController})`, `ReadTab({vm})`, `ReviewTab({vm})` —
  all confirmed matching the plan's Step 3 sample exactly.
- Current `student_providers.dart`'s `lessonDetailOverrideFor` and
  `router.dart`'s `/lesson/:lessonId` route (including the
  `invalidateQuizSession` helper) read in full and confirmed matching the
  plan's Step 5/6 description exactly — the swap described there is
  accurate, no adaptation needed beyond a straight function/import
  rename.
- `student_providers_test.dart` has exactly two `lessonDetailOverrideFor`
  cases to port: `'lessonDetailOverrideFor resolves a real stream, not a
  TypeError'` and `'C4: lessonDetailOverrideFor resolves a
  teacher-authored lesson id without throwing'`.

## Task (follow the plan's steps 1–9 exactly, in TDD order)

1. Write `test/features/student/ar_lab/ar_lab_screen_test.dart` per the
   plan's Step 1 sample (verify it fails first).
2. Implement `ar_lab_screen.dart` per the plan's Step 3 sample verbatim —
   `ArLabScreen extends ConsumerStatefulWidget`, owns one
   `VoiceOverController` for the screen's lifetime, `DefaultTabController`
   with Scan/Read/Review tabs.
3. In `student_providers.dart`: replace `lessonDetailOverrideFor` with
   `arLabOverrideFor` (plan's Step 5 sample), remove the now-unused
   `LessonDetailViewModel`/`lesson_detail_providers.dart` import, add
   `ar_lab_providers.dart` import.
4. In `router.dart`: swap `lessonDetailOverrideFor(...)` →
   `arLabOverrideFor(...)`, `LessonDetailScreen(lessonId: lessonId)` →
   `ArLabScreen(lessonId: lessonId)`, update the import. Leave the
   `Consumer`/`currentStudentIdProvider`/`invalidateQuizSession` structure
   untouched.
5. Delete the three retired Lesson Detail files (`git rm`), delete the
   now-empty `lesson_detail/` dirs if empty.
6. In `student_providers_test.dart`: replace both `lessonDetailOverrideFor`
   cases with `arLabOverrideFor` equivalents proving the same two
   properties (resolves a real stream without a TypeError; resolves a
   teacher-authored lesson id without throwing `StateError`).
7. Run `flutter test` (full suite) — expected all green, watch specifically
   for stray references to the deleted files, and confirm
   `home_screen.dart`'s "Continue where you left off" and
   `lesson_card.dart`'s `context.push('/lesson/${...}')` calls still
   compile (route path is unchanged, only what it renders changed).
8. Commit per the plan's Step 9 git commands (adjusted to also include
   the updated `student_providers_test.dart`).

Report back: final test count, any deviation from the plan and why, any
new finding.
