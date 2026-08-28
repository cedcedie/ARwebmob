// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teacher_quiz.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TeacherQuiz _$TeacherQuizFromJson(Map<String, dynamic> json) {
  return _TeacherQuiz.fromJson(json);
}

/// @nodoc
mixin _$TeacherQuiz {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject => throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;
  List<TeacherQuizQuestion> get questions => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _phaseFromJson, toJson: _phaseToJson, includeIfNull: false)
  QuizPhase get phase => throw _privateConstructorUsedError;

  /// Serializes this TeacherQuiz to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeacherQuiz
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherQuizCopyWith<TeacherQuiz> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherQuizCopyWith<$Res> {
  factory $TeacherQuizCopyWith(
    TeacherQuiz value,
    $Res Function(TeacherQuiz) then,
  ) = _$TeacherQuizCopyWithImpl<$Res, TeacherQuiz>;
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? topicId,
    List<TeacherQuizQuestion> questions,
    String createdAt,
    @JsonKey(
      fromJson: _phaseFromJson,
      toJson: _phaseToJson,
      includeIfNull: false,
    )
    QuizPhase phase,
  });
}

/// @nodoc
class _$TeacherQuizCopyWithImpl<$Res, $Val extends TeacherQuiz>
    implements $TeacherQuizCopyWith<$Res> {
  _$TeacherQuizCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeacherQuiz
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subject = null,
    Object? topicId = freezed,
    Object? questions = null,
    Object? createdAt = null,
    Object? phase = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as SubjectKey,
            topicId: freezed == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                      as String?,
            questions: null == questions
                ? _value.questions
                : questions // ignore: cast_nullable_to_non_nullable
                      as List<TeacherQuizQuestion>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            phase: null == phase
                ? _value.phase
                : phase // ignore: cast_nullable_to_non_nullable
                      as QuizPhase,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TeacherQuizImplCopyWith<$Res>
    implements $TeacherQuizCopyWith<$Res> {
  factory _$$TeacherQuizImplCopyWith(
    _$TeacherQuizImpl value,
    $Res Function(_$TeacherQuizImpl) then,
  ) = __$$TeacherQuizImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? topicId,
    List<TeacherQuizQuestion> questions,
    String createdAt,
    @JsonKey(
      fromJson: _phaseFromJson,
      toJson: _phaseToJson,
      includeIfNull: false,
    )
    QuizPhase phase,
  });
}

/// @nodoc
class __$$TeacherQuizImplCopyWithImpl<$Res>
    extends _$TeacherQuizCopyWithImpl<$Res, _$TeacherQuizImpl>
    implements _$$TeacherQuizImplCopyWith<$Res> {
  __$$TeacherQuizImplCopyWithImpl(
    _$TeacherQuizImpl _value,
    $Res Function(_$TeacherQuizImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TeacherQuiz
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subject = null,
    Object? topicId = freezed,
    Object? questions = null,
    Object? createdAt = null,
    Object? phase = null,
  }) {
    return _then(
      _$TeacherQuizImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as SubjectKey,
        topicId: freezed == topicId
            ? _value.topicId
            : topicId // ignore: cast_nullable_to_non_nullable
                  as String?,
        questions: null == questions
            ? _value._questions
            : questions // ignore: cast_nullable_to_non_nullable
                  as List<TeacherQuizQuestion>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        phase: null == phase
            ? _value.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as QuizPhase,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TeacherQuizImpl implements _TeacherQuiz {
  const _$TeacherQuizImpl({
    required this.id,
    required this.title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required this.subject,
    this.topicId,
    required final List<TeacherQuizQuestion> questions,
    required this.createdAt,
    @JsonKey(
      fromJson: _phaseFromJson,
      toJson: _phaseToJson,
      includeIfNull: false,
    )
    this.phase = QuizPhase.post,
  }) : _questions = questions;

  factory _$TeacherQuizImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherQuizImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  final SubjectKey subject;
  @override
  final String? topicId;
  final List<TeacherQuizQuestion> _questions;
  @override
  List<TeacherQuizQuestion> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  @override
  final String createdAt;
  @override
  @JsonKey(fromJson: _phaseFromJson, toJson: _phaseToJson, includeIfNull: false)
  final QuizPhase phase;

  @override
  String toString() {
    return 'TeacherQuiz(id: $id, title: $title, subject: $subject, topicId: $topicId, questions: $questions, createdAt: $createdAt, phase: $phase)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherQuizImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            const DeepCollectionEquality().equals(
              other._questions,
              _questions,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.phase, phase) || other.phase == phase));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    subject,
    topicId,
    const DeepCollectionEquality().hash(_questions),
    createdAt,
    phase,
  );

  /// Create a copy of TeacherQuiz
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherQuizImplCopyWith<_$TeacherQuizImpl> get copyWith =>
      __$$TeacherQuizImplCopyWithImpl<_$TeacherQuizImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherQuizImplToJson(this);
  }
}

abstract class _TeacherQuiz implements TeacherQuiz {
  const factory _TeacherQuiz({
    required final String id,
    required final String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required final SubjectKey subject,
    final String? topicId,
    required final List<TeacherQuizQuestion> questions,
    required final String createdAt,
    @JsonKey(
      fromJson: _phaseFromJson,
      toJson: _phaseToJson,
      includeIfNull: false,
    )
    final QuizPhase phase,
  }) = _$TeacherQuizImpl;

  factory _TeacherQuiz.fromJson(Map<String, dynamic> json) =
      _$TeacherQuizImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject;
  @override
  String? get topicId;
  @override
  List<TeacherQuizQuestion> get questions;
  @override
  String get createdAt;
  @override
  @JsonKey(fromJson: _phaseFromJson, toJson: _phaseToJson, includeIfNull: false)
  QuizPhase get phase;

  /// Create a copy of TeacherQuiz
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherQuizImplCopyWith<_$TeacherQuizImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
