// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StudentRecord _$StudentRecordFromJson(Map<String, dynamic> json) {
  return _StudentRecord.fromJson(json);
}

/// @nodoc
mixin _$StudentRecord {
  String get id => throw _privateConstructorUsedError;
  String? get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get grade => throw _privateConstructorUsedError;
  String get section => throw _privateConstructorUsedError;
  Map<String, num?> get scores =>
      throw _privateConstructorUsedError; // keyed by 'chemistry'/'biology'/'physics'
  List<String> get completedLessonIds => throw _privateConstructorUsedError;
  List<String> get completedLabExperimentIds =>
      throw _privateConstructorUsedError;
  List<String> get completedQuizIds => throw _privateConstructorUsedError;
  List<String> get unlockedLessonIds => throw _privateConstructorUsedError;
  List<String> get unlockedQuizIds => throw _privateConstructorUsedError;
  List<QuizAttempt> get quizAttempts => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;

  /// Serializes this StudentRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudentRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentRecordCopyWith<StudentRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentRecordCopyWith<$Res> {
  factory $StudentRecordCopyWith(
    StudentRecord value,
    $Res Function(StudentRecord) then,
  ) = _$StudentRecordCopyWithImpl<$Res, StudentRecord>;
  @useResult
  $Res call({
    String id,
    String? uid,
    String name,
    String studentId,
    String grade,
    String section,
    Map<String, num?> scores,
    List<String> completedLessonIds,
    List<String> completedLabExperimentIds,
    List<String> completedQuizIds,
    List<String> unlockedLessonIds,
    List<String> unlockedQuizIds,
    List<QuizAttempt> quizAttempts,
    bool isArchived,
  });
}

/// @nodoc
class _$StudentRecordCopyWithImpl<$Res, $Val extends StudentRecord>
    implements $StudentRecordCopyWith<$Res> {
  _$StudentRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudentRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? uid = freezed,
    Object? name = null,
    Object? studentId = null,
    Object? grade = null,
    Object? section = null,
    Object? scores = null,
    Object? completedLessonIds = null,
    Object? completedLabExperimentIds = null,
    Object? completedQuizIds = null,
    Object? unlockedLessonIds = null,
    Object? unlockedQuizIds = null,
    Object? quizAttempts = null,
    Object? isArchived = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            uid: freezed == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            grade: null == grade
                ? _value.grade
                : grade // ignore: cast_nullable_to_non_nullable
                      as String,
            section: null == section
                ? _value.section
                : section // ignore: cast_nullable_to_non_nullable
                      as String,
            scores: null == scores
                ? _value.scores
                : scores // ignore: cast_nullable_to_non_nullable
                      as Map<String, num?>,
            completedLessonIds: null == completedLessonIds
                ? _value.completedLessonIds
                : completedLessonIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            completedLabExperimentIds: null == completedLabExperimentIds
                ? _value.completedLabExperimentIds
                : completedLabExperimentIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            completedQuizIds: null == completedQuizIds
                ? _value.completedQuizIds
                : completedQuizIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            unlockedLessonIds: null == unlockedLessonIds
                ? _value.unlockedLessonIds
                : unlockedLessonIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            unlockedQuizIds: null == unlockedQuizIds
                ? _value.unlockedQuizIds
                : unlockedQuizIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            quizAttempts: null == quizAttempts
                ? _value.quizAttempts
                : quizAttempts // ignore: cast_nullable_to_non_nullable
                      as List<QuizAttempt>,
            isArchived: null == isArchived
                ? _value.isArchived
                : isArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudentRecordImplCopyWith<$Res>
    implements $StudentRecordCopyWith<$Res> {
  factory _$$StudentRecordImplCopyWith(
    _$StudentRecordImpl value,
    $Res Function(_$StudentRecordImpl) then,
  ) = __$$StudentRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? uid,
    String name,
    String studentId,
    String grade,
    String section,
    Map<String, num?> scores,
    List<String> completedLessonIds,
    List<String> completedLabExperimentIds,
    List<String> completedQuizIds,
    List<String> unlockedLessonIds,
    List<String> unlockedQuizIds,
    List<QuizAttempt> quizAttempts,
    bool isArchived,
  });
}

/// @nodoc
class __$$StudentRecordImplCopyWithImpl<$Res>
    extends _$StudentRecordCopyWithImpl<$Res, _$StudentRecordImpl>
    implements _$$StudentRecordImplCopyWith<$Res> {
  __$$StudentRecordImplCopyWithImpl(
    _$StudentRecordImpl _value,
    $Res Function(_$StudentRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudentRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? uid = freezed,
    Object? name = null,
    Object? studentId = null,
    Object? grade = null,
    Object? section = null,
    Object? scores = null,
    Object? completedLessonIds = null,
    Object? completedLabExperimentIds = null,
    Object? completedQuizIds = null,
    Object? unlockedLessonIds = null,
    Object? unlockedQuizIds = null,
    Object? quizAttempts = null,
    Object? isArchived = null,
  }) {
    return _then(
      _$StudentRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        uid: freezed == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        grade: null == grade
            ? _value.grade
            : grade // ignore: cast_nullable_to_non_nullable
                  as String,
        section: null == section
            ? _value.section
            : section // ignore: cast_nullable_to_non_nullable
                  as String,
        scores: null == scores
            ? _value._scores
            : scores // ignore: cast_nullable_to_non_nullable
                  as Map<String, num?>,
        completedLessonIds: null == completedLessonIds
            ? _value._completedLessonIds
            : completedLessonIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        completedLabExperimentIds: null == completedLabExperimentIds
            ? _value._completedLabExperimentIds
            : completedLabExperimentIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        completedQuizIds: null == completedQuizIds
            ? _value._completedQuizIds
            : completedQuizIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        unlockedLessonIds: null == unlockedLessonIds
            ? _value._unlockedLessonIds
            : unlockedLessonIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        unlockedQuizIds: null == unlockedQuizIds
            ? _value._unlockedQuizIds
            : unlockedQuizIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        quizAttempts: null == quizAttempts
            ? _value._quizAttempts
            : quizAttempts // ignore: cast_nullable_to_non_nullable
                  as List<QuizAttempt>,
        isArchived: null == isArchived
            ? _value.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentRecordImpl implements _StudentRecord {
  const _$StudentRecordImpl({
    required this.id,
    this.uid,
    required this.name,
    required this.studentId,
    required this.grade,
    required this.section,
    required final Map<String, num?> scores,
    required final List<String> completedLessonIds,
    required final List<String> completedLabExperimentIds,
    required final List<String> completedQuizIds,
    required final List<String> unlockedLessonIds,
    required final List<String> unlockedQuizIds,
    required final List<QuizAttempt> quizAttempts,
    this.isArchived = false,
  }) : _scores = scores,
       _completedLessonIds = completedLessonIds,
       _completedLabExperimentIds = completedLabExperimentIds,
       _completedQuizIds = completedQuizIds,
       _unlockedLessonIds = unlockedLessonIds,
       _unlockedQuizIds = unlockedQuizIds,
       _quizAttempts = quizAttempts;

  factory _$StudentRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String? uid;
  @override
  final String name;
  @override
  final String studentId;
  @override
  final String grade;
  @override
  final String section;
  final Map<String, num?> _scores;
  @override
  Map<String, num?> get scores {
    if (_scores is EqualUnmodifiableMapView) return _scores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_scores);
  }

  // keyed by 'chemistry'/'biology'/'physics'
  final List<String> _completedLessonIds;
  // keyed by 'chemistry'/'biology'/'physics'
  @override
  List<String> get completedLessonIds {
    if (_completedLessonIds is EqualUnmodifiableListView)
      return _completedLessonIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedLessonIds);
  }

  final List<String> _completedLabExperimentIds;
  @override
  List<String> get completedLabExperimentIds {
    if (_completedLabExperimentIds is EqualUnmodifiableListView)
      return _completedLabExperimentIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedLabExperimentIds);
  }

  final List<String> _completedQuizIds;
  @override
  List<String> get completedQuizIds {
    if (_completedQuizIds is EqualUnmodifiableListView)
      return _completedQuizIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedQuizIds);
  }

  final List<String> _unlockedLessonIds;
  @override
  List<String> get unlockedLessonIds {
    if (_unlockedLessonIds is EqualUnmodifiableListView)
      return _unlockedLessonIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedLessonIds);
  }

  final List<String> _unlockedQuizIds;
  @override
  List<String> get unlockedQuizIds {
    if (_unlockedQuizIds is EqualUnmodifiableListView) return _unlockedQuizIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedQuizIds);
  }

  final List<QuizAttempt> _quizAttempts;
  @override
  List<QuizAttempt> get quizAttempts {
    if (_quizAttempts is EqualUnmodifiableListView) return _quizAttempts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quizAttempts);
  }

  @override
  @JsonKey()
  final bool isArchived;

  @override
  String toString() {
    return 'StudentRecord(id: $id, uid: $uid, name: $name, studentId: $studentId, grade: $grade, section: $section, scores: $scores, completedLessonIds: $completedLessonIds, completedLabExperimentIds: $completedLabExperimentIds, completedQuizIds: $completedQuizIds, unlockedLessonIds: $unlockedLessonIds, unlockedQuizIds: $unlockedQuizIds, quizAttempts: $quizAttempts, isArchived: $isArchived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.section, section) || other.section == section) &&
            const DeepCollectionEquality().equals(other._scores, _scores) &&
            const DeepCollectionEquality().equals(
              other._completedLessonIds,
              _completedLessonIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._completedLabExperimentIds,
              _completedLabExperimentIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._completedQuizIds,
              _completedQuizIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._unlockedLessonIds,
              _unlockedLessonIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._unlockedQuizIds,
              _unlockedQuizIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._quizAttempts,
              _quizAttempts,
            ) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    uid,
    name,
    studentId,
    grade,
    section,
    const DeepCollectionEquality().hash(_scores),
    const DeepCollectionEquality().hash(_completedLessonIds),
    const DeepCollectionEquality().hash(_completedLabExperimentIds),
    const DeepCollectionEquality().hash(_completedQuizIds),
    const DeepCollectionEquality().hash(_unlockedLessonIds),
    const DeepCollectionEquality().hash(_unlockedQuizIds),
    const DeepCollectionEquality().hash(_quizAttempts),
    isArchived,
  );

  /// Create a copy of StudentRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentRecordImplCopyWith<_$StudentRecordImpl> get copyWith =>
      __$$StudentRecordImplCopyWithImpl<_$StudentRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentRecordImplToJson(this);
  }
}

abstract class _StudentRecord implements StudentRecord {
  const factory _StudentRecord({
    required final String id,
    final String? uid,
    required final String name,
    required final String studentId,
    required final String grade,
    required final String section,
    required final Map<String, num?> scores,
    required final List<String> completedLessonIds,
    required final List<String> completedLabExperimentIds,
    required final List<String> completedQuizIds,
    required final List<String> unlockedLessonIds,
    required final List<String> unlockedQuizIds,
    required final List<QuizAttempt> quizAttempts,
    final bool isArchived,
  }) = _$StudentRecordImpl;

  factory _StudentRecord.fromJson(Map<String, dynamic> json) =
      _$StudentRecordImpl.fromJson;

  @override
  String get id;
  @override
  String? get uid;
  @override
  String get name;
  @override
  String get studentId;
  @override
  String get grade;
  @override
  String get section;
  @override
  Map<String, num?> get scores; // keyed by 'chemistry'/'biology'/'physics'
  @override
  List<String> get completedLessonIds;
  @override
  List<String> get completedLabExperimentIds;
  @override
  List<String> get completedQuizIds;
  @override
  List<String> get unlockedLessonIds;
  @override
  List<String> get unlockedQuizIds;
  @override
  List<QuizAttempt> get quizAttempts;
  @override
  bool get isArchived;

  /// Create a copy of StudentRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentRecordImplCopyWith<_$StudentRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
