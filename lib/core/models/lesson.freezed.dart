// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Lesson _$LessonFromJson(Map<String, dynamic> json) {
  return _Lesson.fromJson(json);
}

/// @nodoc
mixin _$Lesson {
  String get id => throw _privateConstructorUsedError; // e.g. 'q1w1'
  String get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject => throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  List<String> get steps => throw _privateConstructorUsedError;
  String? get labExperimentId => throw _privateConstructorUsedError;
  ARPayload? get arPayload => throw _privateConstructorUsedError;
  bool get hasAR => throw _privateConstructorUsedError;
  String? get pdfUrl => throw _privateConstructorUsedError;
  bool get isUnlockedByDefault => throw _privateConstructorUsedError;
  CurriculumContent? get curriculum => throw _privateConstructorUsedError;
  int? get week => throw _privateConstructorUsedError;
  int? get quarter => throw _privateConstructorUsedError;

  /// Serializes this Lesson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LessonCopyWith<Lesson> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LessonCopyWith<$Res> {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) then) =
      _$LessonCopyWithImpl<$Res, Lesson>;
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? topicId,
    String summary,
    List<String> steps,
    String? labExperimentId,
    ARPayload? arPayload,
    bool hasAR,
    String? pdfUrl,
    bool isUnlockedByDefault,
    CurriculumContent? curriculum,
    int? week,
    int? quarter,
  });

  $ARPayloadCopyWith<$Res>? get arPayload;
  $CurriculumContentCopyWith<$Res>? get curriculum;
}

/// @nodoc
class _$LessonCopyWithImpl<$Res, $Val extends Lesson>
    implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subject = null,
    Object? topicId = freezed,
    Object? summary = null,
    Object? steps = null,
    Object? labExperimentId = freezed,
    Object? arPayload = freezed,
    Object? hasAR = null,
    Object? pdfUrl = freezed,
    Object? isUnlockedByDefault = null,
    Object? curriculum = freezed,
    Object? week = freezed,
    Object? quarter = freezed,
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
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            labExperimentId: freezed == labExperimentId
                ? _value.labExperimentId
                : labExperimentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            arPayload: freezed == arPayload
                ? _value.arPayload
                : arPayload // ignore: cast_nullable_to_non_nullable
                      as ARPayload?,
            hasAR: null == hasAR
                ? _value.hasAR
                : hasAR // ignore: cast_nullable_to_non_nullable
                      as bool,
            pdfUrl: freezed == pdfUrl
                ? _value.pdfUrl
                : pdfUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isUnlockedByDefault: null == isUnlockedByDefault
                ? _value.isUnlockedByDefault
                : isUnlockedByDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            curriculum: freezed == curriculum
                ? _value.curriculum
                : curriculum // ignore: cast_nullable_to_non_nullable
                      as CurriculumContent?,
            week: freezed == week
                ? _value.week
                : week // ignore: cast_nullable_to_non_nullable
                      as int?,
            quarter: freezed == quarter
                ? _value.quarter
                : quarter // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ARPayloadCopyWith<$Res>? get arPayload {
    if (_value.arPayload == null) {
      return null;
    }

    return $ARPayloadCopyWith<$Res>(_value.arPayload!, (value) {
      return _then(_value.copyWith(arPayload: value) as $Val);
    });
  }

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CurriculumContentCopyWith<$Res>? get curriculum {
    if (_value.curriculum == null) {
      return null;
    }

    return $CurriculumContentCopyWith<$Res>(_value.curriculum!, (value) {
      return _then(_value.copyWith(curriculum: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LessonImplCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$$LessonImplCopyWith(
    _$LessonImpl value,
    $Res Function(_$LessonImpl) then,
  ) = __$$LessonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? topicId,
    String summary,
    List<String> steps,
    String? labExperimentId,
    ARPayload? arPayload,
    bool hasAR,
    String? pdfUrl,
    bool isUnlockedByDefault,
    CurriculumContent? curriculum,
    int? week,
    int? quarter,
  });

  @override
  $ARPayloadCopyWith<$Res>? get arPayload;
  @override
  $CurriculumContentCopyWith<$Res>? get curriculum;
}

/// @nodoc
class __$$LessonImplCopyWithImpl<$Res>
    extends _$LessonCopyWithImpl<$Res, _$LessonImpl>
    implements _$$LessonImplCopyWith<$Res> {
  __$$LessonImplCopyWithImpl(
    _$LessonImpl _value,
    $Res Function(_$LessonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subject = null,
    Object? topicId = freezed,
    Object? summary = null,
    Object? steps = null,
    Object? labExperimentId = freezed,
    Object? arPayload = freezed,
    Object? hasAR = null,
    Object? pdfUrl = freezed,
    Object? isUnlockedByDefault = null,
    Object? curriculum = freezed,
    Object? week = freezed,
    Object? quarter = freezed,
  }) {
    return _then(
      _$LessonImpl(
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
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        labExperimentId: freezed == labExperimentId
            ? _value.labExperimentId
            : labExperimentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        arPayload: freezed == arPayload
            ? _value.arPayload
            : arPayload // ignore: cast_nullable_to_non_nullable
                  as ARPayload?,
        hasAR: null == hasAR
            ? _value.hasAR
            : hasAR // ignore: cast_nullable_to_non_nullable
                  as bool,
        pdfUrl: freezed == pdfUrl
            ? _value.pdfUrl
            : pdfUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isUnlockedByDefault: null == isUnlockedByDefault
            ? _value.isUnlockedByDefault
            : isUnlockedByDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        curriculum: freezed == curriculum
            ? _value.curriculum
            : curriculum // ignore: cast_nullable_to_non_nullable
                  as CurriculumContent?,
        week: freezed == week
            ? _value.week
            : week // ignore: cast_nullable_to_non_nullable
                  as int?,
        quarter: freezed == quarter
            ? _value.quarter
            : quarter // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LessonImpl implements _Lesson {
  const _$LessonImpl({
    required this.id,
    required this.title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required this.subject,
    this.topicId,
    required this.summary,
    required final List<String> steps,
    this.labExperimentId,
    this.arPayload,
    this.hasAR = false,
    this.pdfUrl,
    this.isUnlockedByDefault = false,
    this.curriculum,
    this.week,
    this.quarter,
  }) : _steps = steps;

  factory _$LessonImpl.fromJson(Map<String, dynamic> json) =>
      _$$LessonImplFromJson(json);

  @override
  final String id;
  // e.g. 'q1w1'
  @override
  final String title;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  final SubjectKey subject;
  @override
  final String? topicId;
  @override
  final String summary;
  final List<String> _steps;
  @override
  List<String> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  @override
  final String? labExperimentId;
  @override
  final ARPayload? arPayload;
  @override
  @JsonKey()
  final bool hasAR;
  @override
  final String? pdfUrl;
  @override
  @JsonKey()
  final bool isUnlockedByDefault;
  @override
  final CurriculumContent? curriculum;
  @override
  final int? week;
  @override
  final int? quarter;

  @override
  String toString() {
    return 'Lesson(id: $id, title: $title, subject: $subject, topicId: $topicId, summary: $summary, steps: $steps, labExperimentId: $labExperimentId, arPayload: $arPayload, hasAR: $hasAR, pdfUrl: $pdfUrl, isUnlockedByDefault: $isUnlockedByDefault, curriculum: $curriculum, week: $week, quarter: $quarter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LessonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.labExperimentId, labExperimentId) ||
                other.labExperimentId == labExperimentId) &&
            (identical(other.arPayload, arPayload) ||
                other.arPayload == arPayload) &&
            (identical(other.hasAR, hasAR) || other.hasAR == hasAR) &&
            (identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl) &&
            (identical(other.isUnlockedByDefault, isUnlockedByDefault) ||
                other.isUnlockedByDefault == isUnlockedByDefault) &&
            (identical(other.curriculum, curriculum) ||
                other.curriculum == curriculum) &&
            (identical(other.week, week) || other.week == week) &&
            (identical(other.quarter, quarter) || other.quarter == quarter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    subject,
    topicId,
    summary,
    const DeepCollectionEquality().hash(_steps),
    labExperimentId,
    arPayload,
    hasAR,
    pdfUrl,
    isUnlockedByDefault,
    curriculum,
    week,
    quarter,
  );

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LessonImplCopyWith<_$LessonImpl> get copyWith =>
      __$$LessonImplCopyWithImpl<_$LessonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LessonImplToJson(this);
  }
}

abstract class _Lesson implements Lesson {
  const factory _Lesson({
    required final String id,
    required final String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required final SubjectKey subject,
    final String? topicId,
    required final String summary,
    required final List<String> steps,
    final String? labExperimentId,
    final ARPayload? arPayload,
    final bool hasAR,
    final String? pdfUrl,
    final bool isUnlockedByDefault,
    final CurriculumContent? curriculum,
    final int? week,
    final int? quarter,
  }) = _$LessonImpl;

  factory _Lesson.fromJson(Map<String, dynamic> json) = _$LessonImpl.fromJson;

  @override
  String get id; // e.g. 'q1w1'
  @override
  String get title;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject;
  @override
  String? get topicId;
  @override
  String get summary;
  @override
  List<String> get steps;
  @override
  String? get labExperimentId;
  @override
  ARPayload? get arPayload;
  @override
  bool get hasAR;
  @override
  String? get pdfUrl;
  @override
  bool get isUnlockedByDefault;
  @override
  CurriculumContent? get curriculum;
  @override
  int? get week;
  @override
  int? get quarter;

  /// Create a copy of Lesson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LessonImplCopyWith<_$LessonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
