enum QuizPhase {
  pre,
  post;

  /// Absent or unrecognized ⇒ 'post' (legacy quizzes — PROJECT_FLOW.md
  /// Part 4.1).
  static QuizPhase fromFirestore(String? value) {
    return QuizPhase.values.firstWhere(
      (v) => v.name == value,
      orElse: () => QuizPhase.post,
    );
  }

  String get firestoreValue => name;
}
