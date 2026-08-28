enum QuestionType {
  mc,
  tf;

  /// Absent or unrecognized ⇒ 'mc' (back-compat with existing data —
  /// PROJECT_FLOW.md Part 4.1).
  static QuestionType fromFirestore(String? value) {
    return QuestionType.values.firstWhere(
      (v) => v.name == value,
      orElse: () => QuestionType.mc,
    );
  }

  String get firestoreValue => name;
}
