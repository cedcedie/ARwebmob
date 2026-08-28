// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_attempt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QuizAttempt _$QuizAttemptFromJson(Map<String, dynamic> json) {
  return _QuizAttempt.fromJson(json);
}

/// @nodoc
mixin _$QuizAttempt {
  String get id => throw _privateConstructorUsedError;
  String get quizId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  int get attemptNumber => throw _privateConstructorUsedError;
  num get score => throw _privateConstructorUsedError;
  int get totalQuestions => throw _privateConstructorUsedError;
  int get correctAnswers => throw _privateConstructorUsedError;
  List<int> get answers =>
      throw _privateConstructorUsedError; // selected option index per question, in order
  String get timestamp =>
      throw _privateConstructorUsedError; // ISO string, kept as string to match Firestore exactly
  int? get timeSpentSeconds => throw _privateConstructorUsedError;
  bool get locked => throw _privateConstructorUsedError;

  /// Serializes this QuizAttempt to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizAttempt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizAttemptCopyWith<QuizAttempt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizAttemptCopyWith<$Res> {
  factory $QuizAttemptCopyWith(
    QuizAttempt value,
    $Res Function(QuizAttempt) then,
  ) = _$QuizAttemptCopyWithImpl<$Res, QuizAttempt>;
  @useResult
  $Res call({
    String id,
    String quizId,
    String studentId,
    int attemptNumber,
    num score,
    int totalQuestions,
    int correctAnswers,
    List<int> answers,
    String timestamp,
    int? timeSpentSeconds,
    bool locked,
  });
}

/// @nodoc
class _$QuizAttemptCopyWithImpl<$Res, $Val extends QuizAttempt>
    implements $QuizAttemptCopyWith<$Res> {
  _$QuizAttemptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizAttempt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizId = null,
    Object? studentId = null,
    Object? attemptNumber = null,
    Object? score = null,
    Object? totalQuestions = null,
    Object? correctAnswers = null,
    Object? answers = null,
    Object? timestamp = null,
    Object? timeSpentSeconds = freezed,
    Object? locked = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            quizId: null == quizId
                ? _value.quizId
                : quizId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            attemptNumber: null == attemptNumber
                ? _value.attemptNumber
                : attemptNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as num,
            totalQuestions: null == totalQuestions
                ? _value.totalQuestions
                : totalQuestions // ignore: cast_nullable_to_non_nullable
                      as int,
            correctAnswers: null == correctAnswers
                ? _value.correctAnswers
                : correctAnswers // ignore: cast_nullable_to_non_nullable
                      as int,
            answers: null == answers
                ? _value.answers
                : answers // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as String,
            timeSpentSeconds: freezed == timeSpentSeconds
                ? _value.timeSpentSeconds
                : timeSpentSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            locked: null == locked
                ? _value.locked
                : locked // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuizAttemptImplCopyWith<$Res>
    implements $QuizAttemptCopyWith<$Res> {
  factory _$$QuizAttemptImplCopyWith(
    _$QuizAttemptImpl value,
    $Res Function(_$QuizAttemptImpl) then,
  ) = __$$QuizAttemptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String quizId,
    String studentId,
    int attemptNumber,
    num score,
    int totalQuestions,
    int correctAnswers,
    List<int> answers,
    String timestamp,
    int? timeSpentSeconds,
    bool locked,
  });
}

/// @nodoc
class __$$QuizAttemptImplCopyWithImpl<$Res>
    extends _$QuizAttemptCopyWithImpl<$Res, _$QuizAttemptImpl>
    implements _$$QuizAttemptImplCopyWith<$Res> {
  __$$QuizAttemptImplCopyWithImpl(
    _$QuizAttemptImpl _value,
    $Res Function(_$QuizAttemptImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizAttempt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizId = null,
    Object? studentId = null,
    Object? attemptNumber = null,
    Object? score = null,
    Object? totalQuestions = null,
    Object? correctAnswers = null,
    Object? answers = null,
    Object? timestamp = null,
    Object? timeSpentSeconds = freezed,
    Object? locked = null,
  }) {
    return _then(
      _$QuizAttemptImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        quizId: null == quizId
            ? _value.quizId
            : quizId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        attemptNumber: null == attemptNumber
            ? _value.attemptNumber
            : attemptNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as num,
        totalQuestions: null == totalQuestions
            ? _value.totalQuestions
            : totalQuestions // ignore: cast_nullable_to_non_nullable
                  as int,
        correctAnswers: null == correctAnswers
            ? _value.correctAnswers
            : correctAnswers // ignore: cast_nullable_to_non_nullable
                  as int,
        answers: null == answers
            ? _value._answers
            : answers // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        timeSpentSeconds: freezed == timeSpentSeconds
            ? _value.timeSpentSeconds
            : timeSpentSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        locked: null == locked
            ? _value.locked
            : locked // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizAttemptImpl implements _QuizAttempt {
  const _$QuizAttemptImpl({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.attemptNumber,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required final List<int> answers,
    required this.timestamp,
    this.timeSpentSeconds,
    required this.locked,
  }) : _answers = answers;

  factory _$QuizAttemptImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizAttemptImplFromJson(json);

  @override
  final String id;
  @override
  final String quizId;
  @override
  final String studentId;
  @override
  final int attemptNumber;
  @override
  final num score;
  @override
  final int totalQuestions;
  @override
  final int correctAnswers;
  final List<int> _answers;
  @override
  List<int> get answers {
    if (_answers is EqualUnmodifiableListView) return _answers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_answers);
  }

  // selected option index per question, in order
  @override
  final String timestamp;
  // ISO string, kept as string to match Firestore exactly
  @override
  final int? timeSpentSeconds;
  @override
  final bool locked;

  @override
  String toString() {
    return 'QuizAttempt(id: $id, quizId: $quizId, studentId: $studentId, attemptNumber: $attemptNumber, score: $score, totalQuestions: $totalQuestions, correctAnswers: $correctAnswers, answers: $answers, timestamp: $timestamp, timeSpentSeconds: $timeSpentSeconds, locked: $locked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizAttemptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quizId, quizId) || other.quizId == quizId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.attemptNumber, attemptNumber) ||
                other.attemptNumber == attemptNumber) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.totalQuestions, totalQuestions) ||
                other.totalQuestions == totalQuestions) &&
            (identical(other.correctAnswers, correctAnswers) ||
                other.correctAnswers == correctAnswers) &&
            const DeepCollectionEquality().equals(other._answers, _answers) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.timeSpentSeconds, timeSpentSeconds) ||
                other.timeSpentSeconds == timeSpentSeconds) &&
            (identical(other.locked, locked) || other.locked == locked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    quizId,
    studentId,
    attemptNumber,
    score,
    totalQuestions,
    correctAnswers,
    const DeepCollectionEquality().hash(_answers),
    timestamp,
    timeSpentSeconds,
    locked,
  );

  /// Create a copy of QuizAttempt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizAttemptImplCopyWith<_$QuizAttemptImpl> get copyWith =>
      __$$QuizAttemptImplCopyWithImpl<_$QuizAttemptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizAttemptImplToJson(this);
  }
}

abstract class _QuizAttempt implements QuizAttempt {
  const factory _QuizAttempt({
    required final String id,
    required final String quizId,
    required final String studentId,
    required final int attemptNumber,
    required final num score,
    required final int totalQuestions,
    required final int correctAnswers,
    required final List<int> answers,
    required final String timestamp,
    final int? timeSpentSeconds,
    required final bool locked,
  }) = _$QuizAttemptImpl;

  factory _QuizAttempt.fromJson(Map<String, dynamic> json) =
      _$QuizAttemptImpl.fromJson;

  @override
  String get id;
  @override
  String get quizId;
  @override
  String get studentId;
  @override
  int get attemptNumber;
  @override
  num get score;
  @override
  int get totalQuestions;
  @override
  int get correctAnswers;
  @override
  List<int> get answers; // selected option index per question, in order
  @override
  String get timestamp; // ISO string, kept as string to match Firestore exactly
  @override
  int? get timeSpentSeconds;
  @override
  bool get locked;

  /// Create a copy of QuizAttempt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizAttemptImplCopyWith<_$QuizAttemptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
