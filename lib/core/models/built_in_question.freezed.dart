// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'built_in_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BuiltInQuestion _$BuiltInQuestionFromJson(Map<String, dynamic> json) {
  return _BuiltInQuestion.fromJson(json);
}

/// @nodoc
mixin _$BuiltInQuestion {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject => throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;
  String? get lessonId => throw _privateConstructorUsedError;
  String get question => throw _privateConstructorUsedError;
  List<String> get options =>
      throw _privateConstructorUsedError; // exactly 4 slots
  int get correctIndex => throw _privateConstructorUsedError;
  String get hint => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
  QuestionType get type => throw _privateConstructorUsedError;

  /// Serializes this BuiltInQuestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BuiltInQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BuiltInQuestionCopyWith<BuiltInQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BuiltInQuestionCopyWith<$Res> {
  factory $BuiltInQuestionCopyWith(
    BuiltInQuestion value,
    $Res Function(BuiltInQuestion) then,
  ) = _$BuiltInQuestionCopyWithImpl<$Res, BuiltInQuestion>;
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? topicId,
    String? lessonId,
    String question,
    List<String> options,
    int correctIndex,
    String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    QuestionType type,
  });
}

/// @nodoc
class _$BuiltInQuestionCopyWithImpl<$Res, $Val extends BuiltInQuestion>
    implements $BuiltInQuestionCopyWith<$Res> {
  _$BuiltInQuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BuiltInQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subject = null,
    Object? topicId = freezed,
    Object? lessonId = freezed,
    Object? question = null,
    Object? options = null,
    Object? correctIndex = null,
    Object? hint = null,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as SubjectKey,
            topicId: freezed == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lessonId: freezed == lessonId
                ? _value.lessonId
                : lessonId // ignore: cast_nullable_to_non_nullable
                      as String?,
            question: null == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                      as String,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            correctIndex: null == correctIndex
                ? _value.correctIndex
                : correctIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            hint: null == hint
                ? _value.hint
                : hint // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as QuestionType,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BuiltInQuestionImplCopyWith<$Res>
    implements $BuiltInQuestionCopyWith<$Res> {
  factory _$$BuiltInQuestionImplCopyWith(
    _$BuiltInQuestionImpl value,
    $Res Function(_$BuiltInQuestionImpl) then,
  ) = __$$BuiltInQuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? topicId,
    String? lessonId,
    String question,
    List<String> options,
    int correctIndex,
    String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    QuestionType type,
  });
}

/// @nodoc
class __$$BuiltInQuestionImplCopyWithImpl<$Res>
    extends _$BuiltInQuestionCopyWithImpl<$Res, _$BuiltInQuestionImpl>
    implements _$$BuiltInQuestionImplCopyWith<$Res> {
  __$$BuiltInQuestionImplCopyWithImpl(
    _$BuiltInQuestionImpl _value,
    $Res Function(_$BuiltInQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BuiltInQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subject = null,
    Object? topicId = freezed,
    Object? lessonId = freezed,
    Object? question = null,
    Object? options = null,
    Object? correctIndex = null,
    Object? hint = null,
    Object? type = null,
  }) {
    return _then(
      _$BuiltInQuestionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as SubjectKey,
        topicId: freezed == topicId
            ? _value.topicId
            : topicId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lessonId: freezed == lessonId
            ? _value.lessonId
            : lessonId // ignore: cast_nullable_to_non_nullable
                  as String?,
        question: null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        correctIndex: null == correctIndex
            ? _value.correctIndex
            : correctIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        hint: null == hint
            ? _value.hint
            : hint // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as QuestionType,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BuiltInQuestionImpl implements _BuiltInQuestion {
  const _$BuiltInQuestionImpl({
    required this.id,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required this.subject,
    this.topicId,
    this.lessonId,
    required this.question,
    required final List<String> options,
    required this.correctIndex,
    required this.hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    this.type = QuestionType.mc,
  }) : _options = options;

  factory _$BuiltInQuestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$BuiltInQuestionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  final SubjectKey subject;
  @override
  final String? topicId;
  @override
  final String? lessonId;
  @override
  final String question;
  final List<String> _options;
  @override
  List<String> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  // exactly 4 slots
  @override
  final int correctIndex;
  @override
  final String hint;
  @override
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
  final QuestionType type;

  @override
  String toString() {
    return 'BuiltInQuestion(id: $id, subject: $subject, topicId: $topicId, lessonId: $lessonId, question: $question, options: $options, correctIndex: $correctIndex, hint: $hint, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BuiltInQuestionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.lessonId, lessonId) ||
                other.lessonId == lessonId) &&
            (identical(other.question, question) ||
                other.question == question) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.correctIndex, correctIndex) ||
                other.correctIndex == correctIndex) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    subject,
    topicId,
    lessonId,
    question,
    const DeepCollectionEquality().hash(_options),
    correctIndex,
    hint,
    type,
  );

  /// Create a copy of BuiltInQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BuiltInQuestionImplCopyWith<_$BuiltInQuestionImpl> get copyWith =>
      __$$BuiltInQuestionImplCopyWithImpl<_$BuiltInQuestionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BuiltInQuestionImplToJson(this);
  }
}

abstract class _BuiltInQuestion implements BuiltInQuestion {
  const factory _BuiltInQuestion({
    required final String id,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required final SubjectKey subject,
    final String? topicId,
    final String? lessonId,
    required final String question,
    required final List<String> options,
    required final int correctIndex,
    required final String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    final QuestionType type,
  }) = _$BuiltInQuestionImpl;

  factory _BuiltInQuestion.fromJson(Map<String, dynamic> json) =
      _$BuiltInQuestionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject;
  @override
  String? get topicId;
  @override
  String? get lessonId;
  @override
  String get question;
  @override
  List<String> get options; // exactly 4 slots
  @override
  int get correctIndex;
  @override
  String get hint;
  @override
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
  QuestionType get type;

  /// Create a copy of BuiltInQuestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BuiltInQuestionImplCopyWith<_$BuiltInQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
