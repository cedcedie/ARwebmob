// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_unlock_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QuizUnlockCode _$QuizUnlockCodeFromJson(Map<String, dynamic> json) {
  return _QuizUnlockCode.fromJson(json);
}

/// @nodoc
mixin _$QuizUnlockCode {
  String get id => throw _privateConstructorUsedError;
  String get quizId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get generatedAt => throw _privateConstructorUsedError;
  String? get usedAt => throw _privateConstructorUsedError;
  String? get expiresAt => throw _privateConstructorUsedError;
  bool get isUsed => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;

  /// Serializes this QuizUnlockCode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizUnlockCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizUnlockCodeCopyWith<QuizUnlockCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizUnlockCodeCopyWith<$Res> {
  factory $QuizUnlockCodeCopyWith(
    QuizUnlockCode value,
    $Res Function(QuizUnlockCode) then,
  ) = _$QuizUnlockCodeCopyWithImpl<$Res, QuizUnlockCode>;
  @useResult
  $Res call({
    String id,
    String quizId,
    String studentId,
    String code,
    String generatedAt,
    String? usedAt,
    String? expiresAt,
    bool isUsed,
    bool isArchived,
  });
}

/// @nodoc
class _$QuizUnlockCodeCopyWithImpl<$Res, $Val extends QuizUnlockCode>
    implements $QuizUnlockCodeCopyWith<$Res> {
  _$QuizUnlockCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizUnlockCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizId = null,
    Object? studentId = null,
    Object? code = null,
    Object? generatedAt = null,
    Object? usedAt = freezed,
    Object? expiresAt = freezed,
    Object? isUsed = null,
    Object? isArchived = null,
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
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            generatedAt: null == generatedAt
                ? _value.generatedAt
                : generatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            usedAt: freezed == usedAt
                ? _value.usedAt
                : usedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            isUsed: null == isUsed
                ? _value.isUsed
                : isUsed // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$QuizUnlockCodeImplCopyWith<$Res>
    implements $QuizUnlockCodeCopyWith<$Res> {
  factory _$$QuizUnlockCodeImplCopyWith(
    _$QuizUnlockCodeImpl value,
    $Res Function(_$QuizUnlockCodeImpl) then,
  ) = __$$QuizUnlockCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String quizId,
    String studentId,
    String code,
    String generatedAt,
    String? usedAt,
    String? expiresAt,
    bool isUsed,
    bool isArchived,
  });
}

/// @nodoc
class __$$QuizUnlockCodeImplCopyWithImpl<$Res>
    extends _$QuizUnlockCodeCopyWithImpl<$Res, _$QuizUnlockCodeImpl>
    implements _$$QuizUnlockCodeImplCopyWith<$Res> {
  __$$QuizUnlockCodeImplCopyWithImpl(
    _$QuizUnlockCodeImpl _value,
    $Res Function(_$QuizUnlockCodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuizUnlockCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizId = null,
    Object? studentId = null,
    Object? code = null,
    Object? generatedAt = null,
    Object? usedAt = freezed,
    Object? expiresAt = freezed,
    Object? isUsed = null,
    Object? isArchived = null,
  }) {
    return _then(
      _$QuizUnlockCodeImpl(
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
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        generatedAt: null == generatedAt
            ? _value.generatedAt
            : generatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        usedAt: freezed == usedAt
            ? _value.usedAt
            : usedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        isUsed: null == isUsed
            ? _value.isUsed
            : isUsed // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$QuizUnlockCodeImpl implements _QuizUnlockCode {
  const _$QuizUnlockCodeImpl({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.code,
    required this.generatedAt,
    this.usedAt,
    this.expiresAt,
    required this.isUsed,
    this.isArchived = false,
  });

  factory _$QuizUnlockCodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizUnlockCodeImplFromJson(json);

  @override
  final String id;
  @override
  final String quizId;
  @override
  final String studentId;
  @override
  final String code;
  @override
  final String generatedAt;
  @override
  final String? usedAt;
  @override
  final String? expiresAt;
  @override
  final bool isUsed;
  @override
  @JsonKey()
  final bool isArchived;

  @override
  String toString() {
    return 'QuizUnlockCode(id: $id, quizId: $quizId, studentId: $studentId, code: $code, generatedAt: $generatedAt, usedAt: $usedAt, expiresAt: $expiresAt, isUsed: $isUsed, isArchived: $isArchived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizUnlockCodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quizId, quizId) || other.quizId == quizId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.usedAt, usedAt) || other.usedAt == usedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.isUsed, isUsed) || other.isUsed == isUsed) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    quizId,
    studentId,
    code,
    generatedAt,
    usedAt,
    expiresAt,
    isUsed,
    isArchived,
  );

  /// Create a copy of QuizUnlockCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizUnlockCodeImplCopyWith<_$QuizUnlockCodeImpl> get copyWith =>
      __$$QuizUnlockCodeImplCopyWithImpl<_$QuizUnlockCodeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizUnlockCodeImplToJson(this);
  }
}

abstract class _QuizUnlockCode implements QuizUnlockCode {
  const factory _QuizUnlockCode({
    required final String id,
    required final String quizId,
    required final String studentId,
    required final String code,
    required final String generatedAt,
    final String? usedAt,
    final String? expiresAt,
    required final bool isUsed,
    final bool isArchived,
  }) = _$QuizUnlockCodeImpl;

  factory _QuizUnlockCode.fromJson(Map<String, dynamic> json) =
      _$QuizUnlockCodeImpl.fromJson;

  @override
  String get id;
  @override
  String get quizId;
  @override
  String get studentId;
  @override
  String get code;
  @override
  String get generatedAt;
  @override
  String? get usedAt;
  @override
  String? get expiresAt;
  @override
  bool get isUsed;
  @override
  bool get isArchived;

  /// Create a copy of QuizUnlockCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizUnlockCodeImplCopyWith<_$QuizUnlockCodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
