enum SubjectKey {
  chemistry,
  biology,
  physics,
  earthScience;

  static SubjectKey fromFirestore(String value) {
    return SubjectKey.values.firstWhere(
      (v) => v.name == value,
      orElse: () => throw ArgumentError('Unknown SubjectKey: $value'),
    );
  }

  String get firestoreValue => name;
}
