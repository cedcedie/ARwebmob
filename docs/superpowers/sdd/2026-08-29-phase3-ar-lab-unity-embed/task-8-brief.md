# Task 8: Read tab

> ⚠️ Reconstructed after the fact (see Task 2 brief).

**Files:** `lib/features/student/ar_lab/read_tab.dart` (new),
`test/features/student/ar_lab/read_tab_test.dart` (new).

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`. Committed as `8cd7b1c`.

## Ask

Display curriculum content (lesson title + summary) with a "Mark as Read"
button when unread, or a "Read" chip when already read. Dispatched with
confirmed real field names from `ArLabViewModel` (`title`, `summary`,
`isRead` bool, `Future<void> Function() onMarkAsRead`) read directly from
Task 6's file before writing the brief, rather than assumed from the
plan. Presentation-only, no interaction with the modelIndex/trackableName
bridge fix, so dispatched sequentially with Task 9 rather than blocked on
anything.
