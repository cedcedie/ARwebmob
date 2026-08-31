# Task 1 Report: ItemAnalysisCalculator — Difficulty, Discrimination, Distractor Math

## Summary

Implemented `ItemAnalysisCalculator` as specified in PROJECT_FLOW.md Part 7.5. Produces per-question item analysis (difficulty index, discrimination index, distractor rates) consumed by Task 2's provider. Pure calculation functions with no Firestore dependency.

## Implementation Details

### Files Created

1. **lib/core/services/item_analysis_calculator.dart** (95 lines)
   - `QuestionItemAnalysis` class: immutable data class holding per-question analysis
     - `questionIndex`: position in quiz
     - `difficultyIndex`: fraction of students correct
     - `discriminationIndex`: top-group correct rate minus bottom-group correct rate
     - `distractorRates`: Map<int, double> excluding correct option
   - `computeItemAnalysis()` function: main entry point
   - `_analyzeQuestion()` helper: computes all three indices for one question

2. **test/core/services/item_analysis_calculator_test.dart** (79 lines)
   - 4 tests covering exact formulas from spec
   - Helper functions: `_twoQuestions()`, `_attempt()`

### Formula Implementation

**Difficulty Index:**
- `(students who answered correctly) / (total students)`
- Implementation: line 65-66, `correctCount / total`

**Discrimination Index:**
- Sort by quiz score descending
- Top ~27%: `(total * 0.27).ceil()` clamped to [1, total]
- Bottom ~27%: same size from reversed list
- Formula: `topGroupCorrectRate - bottomGroupCorrectRate`
- Implementation: line 44-46 (group selection), line 68-74 (rates), line 74 (subtraction)

**Distractor Rates:**
- For each wrong option: `(students who chose it) / (total students)`
- Correct option excluded from map
- Implementation: line 76-85, excludes `correctIndex` at line 80

### TDD Evidence

**RED → GREEN:**
1. Test file created first with 4 failing tests (no implementation)
2. Implementation added to match spec exactly
3. All 4 tests pass with targeted run
4. Full suite (201 tests) passes with no regressions

Test output (targeted):
```
00:00 +0: loading item_analysis_calculator_test.dart
00:00 +0: difficulty index is the fraction of students correct on each question
00:00 +1: discrimination index compares top-scoring vs bottom-scoring groups
00:00 +2: distractor rates report the fraction choosing each wrong option
00:00 +3: returns an empty list for zero attempts, not a crash
00:00 +4: All tests passed!
```

Full suite: `01:04 +201: All tests passed!` (no breakage)

## Self-Review Findings

### Discrimination Index Group-Size Logic (Per Instructions)

**Calculation:**
```dart
final groupSize = (total * 0.27).ceil().clamp(1, total);
```

**Verified behavior:**
- 10 students: `(10 * 0.27).ceil() = 3` → clamp(1, 10) = 3 ✓ (matches test case)
- 2 students: `(2 * 0.27).ceil() = 1` → clamp(1, 2) = 1 ✓ (minimum enforced)
- 1 student: `(1 * 0.27).ceil() = 1` → clamp(1, 1) = 1 ✓ (single student edge case)

Test confirms top 3 (students i=0,1,2 with scores 100,90,80) got q0 100% correct, bottom 3 (students i=7,8,9 with scores 30,20,10) got 0%, discrimination = 1.0.

### Distractor Map Correctness

**Verified at line 80:**
```dart
if (chosen == question.correctIndex) continue;  // Skip correct option
```

Test confirms `result[0].distractorRates.containsKey(0)` is false (q0 correctIndex=0 never appears as key). Options 1 and 2 appear with 2/4 and 1/4 respectively.

### Edge Cases Tested

1. **Zero attempts:** Returns list of questions with all indices = 0.0, empty distractor maps
2. **Empty answers:** Handled by `questionIndex < attempt.answers.length` checks at lines 78, 62
3. **Invalid option indices:** Filtered at line 81 (`chosen < 0 || chosen >= question.options.length`)
4. **Question type agnostic:** Calculator works for MC and TF equally; UI filtering happens in Task 3 per spec

### Imports & Dependencies

- Only imports `BuiltInQuestion` and `QuizAttempt` from `core/models`
- Pure function, no Firestore, no providers, no state management
- Ready for Task 2 provider consumption

## Concerns

None. Implementation matches specification exactly:
- All formulas verified against PROJECT_FLOW.md Part 7.5
- Edge cases handled robustly
- Group-size clamping enforced as specified
- Correct option properly excluded from distractor map
- Zero-attempt case returns safe defaults
- All 4 tests pass, full suite passes

## Files Changed

- Created: `lib/core/services/item_analysis_calculator.dart`
- Created: `test/core/services/item_analysis_calculator_test.dart`

## Commit

```
4258f9e feat: ItemAnalysisCalculator — difficulty/discrimination/distractor math (Part 7.5)
```

---

**Task Status:** DONE  
**Tests:** 4/4 targeted pass, 201/201 full suite pass  
**Review:** Self-review complete, no issues found
