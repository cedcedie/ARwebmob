# Task 2 Report: Item Analysis Provider — Resolve Attempts + Question Bank

## Implementation Summary

Successfully implemented Task 2 of the Phase 5 Item Analysis pipeline. This task bridges the `ItemAnalysisCalculator` from Task 1 with the student attempt data to produce a view model ready for the item analysis screen.

## Files Changed

1. **Created:** `lib/features/teacher/quizzes/item_analysis_providers.dart`
   - Defined `ItemAnalysisViewModel` class with properties: `quizTitle`, `questions`, `results`, `attemptCount`
   - Implemented `itemAnalysisViewModelProvider` as a StreamProvider.autoDispose.family keyed on quizId
   - Implemented `buildItemAnalysisViewModel` function that:
     - Resolves the built-in question bank based on quiz phase (pre/post) and lesson ID
     - Watches all students via StudentRepository
     - Filters quiz attempts to only match the requested quizId
     - Runs computeItemAnalysis on the filtered attempts
     - Returns a stream of ItemAnalysisViewModel

2. **Created:** `test/features/teacher/quizzes/item_analysis_providers_test.dart`
   - Test 1: Verifies provider resolves question bank and collects all attempts on a specific quiz
   - Test 2: Verifies provider ignores attempts on other quizzes (different quizId)

## Test Results

### Focused Test Suite (Task 2)
```
00:00 +0: loading item_analysis_providers_test.dart
00:00 +0: resolves the built-in question bank and every attempt on this quiz ✓
00:00 +1: ignores attempts on other quizzes ✓
00:00 +2: All tests passed!
```

### Full Test Suite
```
01:27 +203: All tests passed!
```

No regressions detected. All 203 tests in the codebase pass.

## TDD Evidence

**RED Phase:** Test file created with failing tests (file didn't exist)

**GREEN Phase:** 
- Implemented provider according to specification
- Both focused tests pass
- Full test suite passes (203 tests)

## Self-Review Findings

### QuizId Filtering (Primary Concern)
Verified that the provider correctly filters attempts to only those matching the requested quizId:

```dart
final attempts = [
  for (final student in students)
    for (final attempt in student.quizAttempts)
      if (attempt.quizId == quizId) attempt,  // ← Exact quizId match required
];
```

Test 2 specifically validates this behavior:
- Student saves attempt on preId quiz
- Provider is queried with postId quiz
- Result: attemptCount = 0 (correctly filtered)
- Expected: 0 ✓

### Architecture
- Provider follows Riverpod patterns consistent with the codebase
- StreamProvider.autoDispose.family correctly keyed on quizId string
- Uses dependency injection pattern (StudentRepository passed in)
- Integrates smoothly with existing computeItemAnalysis from Task 1
- Built-in question resolution handles both pre and post quiz phases

### Known Scope Limitation (Not a Bug)
As specified in the brief, teacher-linked quizzes (non-builtin quiz IDs) currently return an empty question list. This is intentional and documented - real implementation will be added in Task 3 once QuizRepository API is confirmed.

## Concerns

None. Implementation matches specification exactly, all tests pass, filtering logic verified.

## Commit

```
6d80ebd feat: item analysis provider — resolve attempts + built-in question bank
```

## Next Task

Task 3 will wire this provider to the item analysis screen and add teacher-linked quiz support via QuizRepository.
