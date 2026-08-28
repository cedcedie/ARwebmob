// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teacher_quiz_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TeacherQuizQuestion _$TeacherQuizQuestionFromJson(Map<String, dynamic> json) {
  return _TeacherQuizQuestion.fromJson(json);
}

/// @nodoc
mixin _$TeacherQuizQuestion {
  String get question => throw _privateConstructorUsedError;
  List<String> get options =>
      throw _privateConstructorUsedError; // exactly 4 slots
  int get correctIndex => throw _privateConstructorUsedError;
  String get hint => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
  QuestionType get type => throw _privateConstructorUsedError;

  /// Serializes this TeacherQuizQuestion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeacherQuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherQuizQuestionCopyWith<TeacherQuizQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherQuizQuestionCopyWith<$Res> {
  factory $TeacherQuizQuestionCopyWith(
    TeacherQuizQuestion value,
    $Res Function(TeacherQuizQuestion) then,
  ) = _$TeacherQuizQuestionCopyWithImpl<$Res, TeacherQuizQuestion>;
  @useResult
  $Res call({
    String question,
    List<String> options,
    int correctIndex,
    String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    QuestionType type,
  });
}

/// @nodoc
class _$TeacherQuizQuestionCopyWithImpl<$Res, $Val extends TeacherQuizQuestion>
    implements $TeacherQuizQuestionCopyWith<$Res> {
  _$TeacherQuizQuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeacherQuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? options = null,
    Object? correctIndex = null,
    Object? hint = null,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
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
abstract class _$$TeacherQuizQuestionImplCopyWith<$Res>
    implements $TeacherQuizQuestionCopyWith<$Res> {
  factory _$$TeacherQuizQuestionImplCopyWith(
    _$TeacherQuizQuestionImpl value,
    $Res Function(_$TeacherQuizQuestionImpl) then,
  ) = __$$TeacherQuizQuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String question,
    List<String> options,
    int correctIndex,
    String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    QuestionType type,
  });
}

/// @nodoc
class __$$TeacherQuizQuestionImplCopyWithImpl<$Res>
    extends _$TeacherQuizQuestionCopyWithImpl<$Res, _$TeacherQuizQuestionImpl>
    implements _$$TeacherQuizQuestionImplCopyWith<$Res> {
  __$$TeacherQuizQuestionImplCopyWithImpl(
    _$TeacherQuizQuestionImpl _value,
    $Res Function(_$TeacherQuizQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TeacherQuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? options = null,
    Object? correctIndex = null,
    Object? hint = null,
    Object? type = null,
  }) {
    return _then(
      _$TeacherQuizQuestionImpl(
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
class _$TeacherQuizQuestionImpl implements _TeacherQuizQuestion {
  const _$TeacherQuizQuestionImpl({
    required this.question,
    required final List<String> options,
    required this.correctIndex,
    required this.hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    this.type = QuestionType.mc,
  }) : _options = options;

  factory _$TeacherQuizQuestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherQuizQuestionImplFromJson(json);

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
    return 'TeacherQuizQuestion(question: $question, options: $options, correctIndex: $correctIndex, hint: $hint, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherQuizQuestionImpl &&
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
    question,
    const DeepCollectionEquality().hash(_options),
    correctIndex,
    hint,
    type,
  );

  /// Create a copy of TeacherQuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherQuizQuestionImplCopyWith<_$TeacherQuizQuestionImpl> get copyWith =>
      __$$TeacherQuizQuestionImplCopyWithImpl<_$TeacherQuizQuestionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherQuizQuestionImplToJson(this);
  }
}

abstract class _TeacherQuizQuestion implements TeacherQuizQuestion {
  const factory _TeacherQuizQuestion({
    required final String question,
    required final List<String> options,
    required final int correctIndex,
    required final String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    final QuestionType type,
  }) = _$TeacherQuizQuestionImpl;

  factory _TeacherQuizQuestion.fromJson(Map<String, dynamic> json) =
      _$TeacherQuizQuestionImpl.fromJson;

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

  /// Create a copy of TeacherQuizQuestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherQuizQuestionImplCopyWith<_$TeacherQuizQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
