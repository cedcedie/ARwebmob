// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teacher_lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TeacherLesson _$TeacherLessonFromJson(Map<String, dynamic> json) {
  return _TeacherLesson.fromJson(json);
}

/// @nodoc
mixin _$TeacherLesson {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get linkedQuizId => throw _privateConstructorUsedError;
  String? get summary => throw _privateConstructorUsedError;
  List<String>? get steps => throw _privateConstructorUsedError;
  String? get labExperimentId => throw _privateConstructorUsedError;
  ARPayload? get arPayload => throw _privateConstructorUsedError;
  bool? get isPredefined => throw _privateConstructorUsedError;
  int? get quarter => throw _privateConstructorUsedError;
  int? get week => throw _privateConstructorUsedError;
  String? get pdfUrl => throw _privateConstructorUsedError;
  List<String>? get learningObjectives => throw _privateConstructorUsedError;
  List<String>? get keyLearningSteps => throw _privateConstructorUsedError;
  List<String>? get keyVocabulary => throw _privateConstructorUsedError;
  int? get arModelIndex => throw _privateConstructorUsedError;
  String? get arContext => throw _privateConstructorUsedError;
  bool? get hasAR => throw _privateConstructorUsedError;
  CurriculumContent? get curriculum => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;

  /// Serializes this TeacherLesson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeacherLesson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherLessonCopyWith<TeacherLesson> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherLessonCopyWith<$Res> {
  factory $TeacherLessonCopyWith(
    TeacherLesson value,
    $Res Function(TeacherLesson) then,
  ) = _$TeacherLessonCopyWithImpl<$Res, TeacherLesson>;
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? content,
    String? createdAt,
    String? linkedQuizId,
    String? summary,
    List<String>? steps,
    String? labExperimentId,
    ARPayload? arPayload,
    bool? isPredefined,
    int? quarter,
    int? week,
    String? pdfUrl,
    List<String>? learningObjectives,
    List<String>? keyLearningSteps,
    List<String>? keyVocabulary,
    int? arModelIndex,
    String? arContext,
    bool? hasAR,
    CurriculumContent? curriculum,
    bool isArchived,
  });

  $ARPayloadCopyWith<$Res>? get arPayload;
  $CurriculumContentCopyWith<$Res>? get curriculum;
}

/// @nodoc
class _$TeacherLessonCopyWithImpl<$Res, $Val extends TeacherLesson>
    implements $TeacherLessonCopyWith<$Res> {
  _$TeacherLessonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeacherLesson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subject = null,
    Object? content = freezed,
    Object? createdAt = freezed,
    Object? linkedQuizId = freezed,
    Object? summary = freezed,
    Object? steps = freezed,
    Object? labExperimentId = freezed,
    Object? arPayload = freezed,
    Object? isPredefined = freezed,
    Object? quarter = freezed,
    Object? week = freezed,
    Object? pdfUrl = freezed,
    Object? learningObjectives = freezed,
    Object? keyLearningSteps = freezed,
    Object? keyVocabulary = freezed,
    Object? arModelIndex = freezed,
    Object? arContext = freezed,
    Object? hasAR = freezed,
    Object? curriculum = freezed,
    Object? isArchived = null,
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
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            linkedQuizId: freezed == linkedQuizId
                ? _value.linkedQuizId
                : linkedQuizId // ignore: cast_nullable_to_non_nullable
                      as String?,
            summary: freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String?,
            steps: freezed == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            labExperimentId: freezed == labExperimentId
                ? _value.labExperimentId
                : labExperimentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            arPayload: freezed == arPayload
                ? _value.arPayload
                : arPayload // ignore: cast_nullable_to_non_nullable
                      as ARPayload?,
            isPredefined: freezed == isPredefined
                ? _value.isPredefined
                : isPredefined // ignore: cast_nullable_to_non_nullable
                      as bool?,
            quarter: freezed == quarter
                ? _value.quarter
                : quarter // ignore: cast_nullable_to_non_nullable
                      as int?,
            week: freezed == week
                ? _value.week
                : week // ignore: cast_nullable_to_non_nullable
                      as int?,
            pdfUrl: freezed == pdfUrl
                ? _value.pdfUrl
                : pdfUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            learningObjectives: freezed == learningObjectives
                ? _value.learningObjectives
                : learningObjectives // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            keyLearningSteps: freezed == keyLearningSteps
                ? _value.keyLearningSteps
                : keyLearningSteps // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            keyVocabulary: freezed == keyVocabulary
                ? _value.keyVocabulary
                : keyVocabulary // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            arModelIndex: freezed == arModelIndex
                ? _value.arModelIndex
                : arModelIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            arContext: freezed == arContext
                ? _value.arContext
                : arContext // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasAR: freezed == hasAR
                ? _value.hasAR
                : hasAR // ignore: cast_nullable_to_non_nullable
                      as bool?,
            curriculum: freezed == curriculum
                ? _value.curriculum
                : curriculum // ignore: cast_nullable_to_non_nullable
                      as CurriculumContent?,
            isArchived: null == isArchived
                ? _value.isArchived
                : isArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of TeacherLesson
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

  /// Create a copy of TeacherLesson
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
abstract class _$$TeacherLessonImplCopyWith<$Res>
    implements $TeacherLessonCopyWith<$Res> {
  factory _$$TeacherLessonImplCopyWith(
    _$TeacherLessonImpl value,
    $Res Function(_$TeacherLessonImpl) then,
  ) = __$$TeacherLessonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    SubjectKey subject,
    String? content,
    String? createdAt,
    String? linkedQuizId,
    String? summary,
    List<String>? steps,
    String? labExperimentId,
    ARPayload? arPayload,
    bool? isPredefined,
    int? quarter,
    int? week,
    String? pdfUrl,
    List<String>? learningObjectives,
    List<String>? keyLearningSteps,
    List<String>? keyVocabulary,
    int? arModelIndex,
    String? arContext,
    bool? hasAR,
    CurriculumContent? curriculum,
    bool isArchived,
  });

  @override
  $ARPayloadCopyWith<$Res>? get arPayload;
  @override
  $CurriculumContentCopyWith<$Res>? get curriculum;
}

/// @nodoc
class __$$TeacherLessonImplCopyWithImpl<$Res>
    extends _$TeacherLessonCopyWithImpl<$Res, _$TeacherLessonImpl>
    implements _$$TeacherLessonImplCopyWith<$Res> {
  __$$TeacherLessonImplCopyWithImpl(
    _$TeacherLessonImpl _value,
    $Res Function(_$TeacherLessonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TeacherLesson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subject = null,
    Object? content = freezed,
    Object? createdAt = freezed,
    Object? linkedQuizId = freezed,
    Object? summary = freezed,
    Object? steps = freezed,
    Object? labExperimentId = freezed,
    Object? arPayload = freezed,
    Object? isPredefined = freezed,
    Object? quarter = freezed,
    Object? week = freezed,
    Object? pdfUrl = freezed,
    Object? learningObjectives = freezed,
    Object? keyLearningSteps = freezed,
    Object? keyVocabulary = freezed,
    Object? arModelIndex = freezed,
    Object? arContext = freezed,
    Object? hasAR = freezed,
    Object? curriculum = freezed,
    Object? isArchived = null,
  }) {
    return _then(
      _$TeacherLessonImpl(
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
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        linkedQuizId: freezed == linkedQuizId
            ? _value.linkedQuizId
            : linkedQuizId // ignore: cast_nullable_to_non_nullable
                  as String?,
        summary: freezed == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String?,
        steps: freezed == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        labExperimentId: freezed == labExperimentId
            ? _value.labExperimentId
            : labExperimentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        arPayload: freezed == arPayload
            ? _value.arPayload
            : arPayload // ignore: cast_nullable_to_non_nullable
                  as ARPayload?,
        isPredefined: freezed == isPredefined
            ? _value.isPredefined
            : isPredefined // ignore: cast_nullable_to_non_nullable
                  as bool?,
        quarter: freezed == quarter
            ? _value.quarter
            : quarter // ignore: cast_nullable_to_non_nullable
                  as int?,
        week: freezed == week
            ? _value.week
            : week // ignore: cast_nullable_to_non_nullable
                  as int?,
        pdfUrl: freezed == pdfUrl
            ? _value.pdfUrl
            : pdfUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        learningObjectives: freezed == learningObjectives
            ? _value._learningObjectives
            : learningObjectives // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        keyLearningSteps: freezed == keyLearningSteps
            ? _value._keyLearningSteps
            : keyLearningSteps // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        keyVocabulary: freezed == keyVocabulary
            ? _value._keyVocabulary
            : keyVocabulary // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        arModelIndex: freezed == arModelIndex
            ? _value.arModelIndex
            : arModelIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        arContext: freezed == arContext
            ? _value.arContext
            : arContext // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasAR: freezed == hasAR
            ? _value.hasAR
            : hasAR // ignore: cast_nullable_to_non_nullable
                  as bool?,
        curriculum: freezed == curriculum
            ? _value.curriculum
            : curriculum // ignore: cast_nullable_to_non_nullable
                  as CurriculumContent?,
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
class _$TeacherLessonImpl implements _TeacherLesson {
  const _$TeacherLessonImpl({
    required this.id,
    required this.title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required this.subject,
    this.content,
    this.createdAt,
    this.linkedQuizId,
    this.summary,
    final List<String>? steps,
    this.labExperimentId,
    this.arPayload,
    this.isPredefined,
    this.quarter,
    this.week,
    this.pdfUrl,
    final List<String>? learningObjectives,
    final List<String>? keyLearningSteps,
    final List<String>? keyVocabulary,
    this.arModelIndex,
    this.arContext,
    this.hasAR,
    this.curriculum,
    this.isArchived = false,
  }) : _steps = steps,
       _learningObjectives = learningObjectives,
       _keyLearningSteps = keyLearningSteps,
       _keyVocabulary = keyVocabulary;

  factory _$TeacherLessonImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherLessonImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  final SubjectKey subject;
  @override
  final String? content;
  @override
  final String? createdAt;
  @override
  final String? linkedQuizId;
  @override
  final String? summary;
  final List<String>? _steps;
  @override
  List<String>? get steps {
    final value = _steps;
    if (value == null) return null;
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? labExperimentId;
  @override
  final ARPayload? arPayload;
  @override
  final bool? isPredefined;
  @override
  final int? quarter;
  @override
  final int? week;
  @override
  final String? pdfUrl;
  final List<String>? _learningObjectives;
  @override
  List<String>? get learningObjectives {
    final value = _learningObjectives;
    if (value == null) return null;
    if (_learningObjectives is EqualUnmodifiableListView)
      return _learningObjectives;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _keyLearningSteps;
  @override
  List<String>? get keyLearningSteps {
    final value = _keyLearningSteps;
    if (value == null) return null;
    if (_keyLearningSteps is EqualUnmodifiableListView)
      return _keyLearningSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _keyVocabulary;
  @override
  List<String>? get keyVocabulary {
    final value = _keyVocabulary;
    if (value == null) return null;
    if (_keyVocabulary is EqualUnmodifiableListView) return _keyVocabulary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? arModelIndex;
  @override
  final String? arContext;
  @override
  final bool? hasAR;
  @override
  final CurriculumContent? curriculum;
  @override
  @JsonKey()
  final bool isArchived;

  @override
  String toString() {
    return 'TeacherLesson(id: $id, title: $title, subject: $subject, content: $content, createdAt: $createdAt, linkedQuizId: $linkedQuizId, summary: $summary, steps: $steps, labExperimentId: $labExperimentId, arPayload: $arPayload, isPredefined: $isPredefined, quarter: $quarter, week: $week, pdfUrl: $pdfUrl, learningObjectives: $learningObjectives, keyLearningSteps: $keyLearningSteps, keyVocabulary: $keyVocabulary, arModelIndex: $arModelIndex, arContext: $arContext, hasAR: $hasAR, curriculum: $curriculum, isArchived: $isArchived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherLessonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.linkedQuizId, linkedQuizId) ||
                other.linkedQuizId == linkedQuizId) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.labExperimentId, labExperimentId) ||
                other.labExperimentId == labExperimentId) &&
            (identical(other.arPayload, arPayload) ||
                other.arPayload == arPayload) &&
            (identical(other.isPredefined, isPredefined) ||
                other.isPredefined == isPredefined) &&
            (identical(other.quarter, quarter) || other.quarter == quarter) &&
            (identical(other.week, week) || other.week == week) &&
            (identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl) &&
            const DeepCollectionEquality().equals(
              other._learningObjectives,
              _learningObjectives,
            ) &&
            const DeepCollectionEquality().equals(
              other._keyLearningSteps,
              _keyLearningSteps,
            ) &&
            const DeepCollectionEquality().equals(
              other._keyVocabulary,
              _keyVocabulary,
            ) &&
            (identical(other.arModelIndex, arModelIndex) ||
                other.arModelIndex == arModelIndex) &&
            (identical(other.arContext, arContext) ||
                other.arContext == arContext) &&
            (identical(other.hasAR, hasAR) || other.hasAR == hasAR) &&
            (identical(other.curriculum, curriculum) ||
                other.curriculum == curriculum) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    subject,
    content,
    createdAt,
    linkedQuizId,
    summary,
    const DeepCollectionEquality().hash(_steps),
    labExperimentId,
    arPayload,
    isPredefined,
    quarter,
    week,
    pdfUrl,
    const DeepCollectionEquality().hash(_learningObjectives),
    const DeepCollectionEquality().hash(_keyLearningSteps),
    const DeepCollectionEquality().hash(_keyVocabulary),
    arModelIndex,
    arContext,
    hasAR,
    curriculum,
    isArchived,
  ]);

  /// Create a copy of TeacherLesson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherLessonImplCopyWith<_$TeacherLessonImpl> get copyWith =>
      __$$TeacherLessonImplCopyWithImpl<_$TeacherLessonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherLessonImplToJson(this);
  }
}

abstract class _TeacherLesson implements TeacherLesson {
  const factory _TeacherLesson({
    required final String id,
    required final String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required final SubjectKey subject,
    final String? content,
    final String? createdAt,
    final String? linkedQuizId,
    final String? summary,
    final List<String>? steps,
    final String? labExperimentId,
    final ARPayload? arPayload,
    final bool? isPredefined,
    final int? quarter,
    final int? week,
    final String? pdfUrl,
    final List<String>? learningObjectives,
    final List<String>? keyLearningSteps,
    final List<String>? keyVocabulary,
    final int? arModelIndex,
    final String? arContext,
    final bool? hasAR,
    final CurriculumContent? curriculum,
    final bool isArchived,
  }) = _$TeacherLessonImpl;

  factory _TeacherLesson.fromJson(Map<String, dynamic> json) =
      _$TeacherLessonImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
  SubjectKey get subject;
  @override
  String? get content;
  @override
  String? get createdAt;
  @override
  String? get linkedQuizId;
  @override
  String? get summary;
  @override
  List<String>? get steps;
  @override
  String? get labExperimentId;
  @override
  ARPayload? get arPayload;
  @override
  bool? get isPredefined;
  @override
  int? get quarter;
  @override
  int? get week;
  @override
  String? get pdfUrl;
  @override
  List<String>? get learningObjectives;
  @override
  List<String>? get keyLearningSteps;
  @override
  List<String>? get keyVocabulary;
  @override
  int? get arModelIndex;
  @override
  String? get arContext;
  @override
  bool? get hasAR;
  @override
  CurriculumContent? get curriculum;
  @override
  bool get isArchived;

  /// Create a copy of TeacherLesson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherLessonImplCopyWith<_$TeacherLessonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
