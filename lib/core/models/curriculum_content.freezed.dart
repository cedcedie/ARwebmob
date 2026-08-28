// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'curriculum_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CurriculumIntegration _$CurriculumIntegrationFromJson(
  Map<String, dynamic> json,
) {
  return _CurriculumIntegration.fromJson(json);
}

/// @nodoc
mixin _$CurriculumIntegration {
  List<String>? get qualities => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this CurriculumIntegration to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CurriculumIntegration
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CurriculumIntegrationCopyWith<CurriculumIntegration> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurriculumIntegrationCopyWith<$Res> {
  factory $CurriculumIntegrationCopyWith(
    CurriculumIntegration value,
    $Res Function(CurriculumIntegration) then,
  ) = _$CurriculumIntegrationCopyWithImpl<$Res, CurriculumIntegration>;
  @useResult
  $Res call({List<String>? qualities, String? description});
}

/// @nodoc
class _$CurriculumIntegrationCopyWithImpl<
  $Res,
  $Val extends CurriculumIntegration
>
    implements $CurriculumIntegrationCopyWith<$Res> {
  _$CurriculumIntegrationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CurriculumIntegration
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? qualities = freezed, Object? description = freezed}) {
    return _then(
      _value.copyWith(
            qualities: freezed == qualities
                ? _value.qualities
                : qualities // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CurriculumIntegrationImplCopyWith<$Res>
    implements $CurriculumIntegrationCopyWith<$Res> {
  factory _$$CurriculumIntegrationImplCopyWith(
    _$CurriculumIntegrationImpl value,
    $Res Function(_$CurriculumIntegrationImpl) then,
  ) = __$$CurriculumIntegrationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String>? qualities, String? description});
}

/// @nodoc
class __$$CurriculumIntegrationImplCopyWithImpl<$Res>
    extends
        _$CurriculumIntegrationCopyWithImpl<$Res, _$CurriculumIntegrationImpl>
    implements _$$CurriculumIntegrationImplCopyWith<$Res> {
  __$$CurriculumIntegrationImplCopyWithImpl(
    _$CurriculumIntegrationImpl _value,
    $Res Function(_$CurriculumIntegrationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CurriculumIntegration
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? qualities = freezed, Object? description = freezed}) {
    return _then(
      _$CurriculumIntegrationImpl(
        qualities: freezed == qualities
            ? _value._qualities
            : qualities // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CurriculumIntegrationImpl implements _CurriculumIntegration {
  const _$CurriculumIntegrationImpl({
    final List<String>? qualities,
    this.description,
  }) : _qualities = qualities;

  factory _$CurriculumIntegrationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CurriculumIntegrationImplFromJson(json);

  final List<String>? _qualities;
  @override
  List<String>? get qualities {
    final value = _qualities;
    if (value == null) return null;
    if (_qualities is EqualUnmodifiableListView) return _qualities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? description;

  @override
  String toString() {
    return 'CurriculumIntegration(qualities: $qualities, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurriculumIntegrationImpl &&
            const DeepCollectionEquality().equals(
              other._qualities,
              _qualities,
            ) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_qualities),
    description,
  );

  /// Create a copy of CurriculumIntegration
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CurriculumIntegrationImplCopyWith<_$CurriculumIntegrationImpl>
  get copyWith =>
      __$$CurriculumIntegrationImplCopyWithImpl<_$CurriculumIntegrationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CurriculumIntegrationImplToJson(this);
  }
}

abstract class _CurriculumIntegration implements CurriculumIntegration {
  const factory _CurriculumIntegration({
    final List<String>? qualities,
    final String? description,
  }) = _$CurriculumIntegrationImpl;

  factory _CurriculumIntegration.fromJson(Map<String, dynamic> json) =
      _$CurriculumIntegrationImpl.fromJson;

  @override
  List<String>? get qualities;
  @override
  String? get description;

  /// Create a copy of CurriculumIntegration
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CurriculumIntegrationImplCopyWith<_$CurriculumIntegrationImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CurriculumContent _$CurriculumContentFromJson(Map<String, dynamic> json) {
  return _CurriculumContent.fromJson(json);
}

/// @nodoc
mixin _$CurriculumContent {
  String? get standards => throw _privateConstructorUsedError;
  String? get performanceStandards => throw _privateConstructorUsedError;
  List<String>? get learningCompetencies => throw _privateConstructorUsedError;
  List<String>? get objectives => throw _privateConstructorUsedError;
  String? get contentDetails => throw _privateConstructorUsedError;
  CurriculumIntegration? get integration => throw _privateConstructorUsedError;

  /// Serializes this CurriculumContent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CurriculumContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CurriculumContentCopyWith<CurriculumContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurriculumContentCopyWith<$Res> {
  factory $CurriculumContentCopyWith(
    CurriculumContent value,
    $Res Function(CurriculumContent) then,
  ) = _$CurriculumContentCopyWithImpl<$Res, CurriculumContent>;
  @useResult
  $Res call({
    String? standards,
    String? performanceStandards,
    List<String>? learningCompetencies,
    List<String>? objectives,
    String? contentDetails,
    CurriculumIntegration? integration,
  });

  $CurriculumIntegrationCopyWith<$Res>? get integration;
}

/// @nodoc
class _$CurriculumContentCopyWithImpl<$Res, $Val extends CurriculumContent>
    implements $CurriculumContentCopyWith<$Res> {
  _$CurriculumContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CurriculumContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? standards = freezed,
    Object? performanceStandards = freezed,
    Object? learningCompetencies = freezed,
    Object? objectives = freezed,
    Object? contentDetails = freezed,
    Object? integration = freezed,
  }) {
    return _then(
      _value.copyWith(
            standards: freezed == standards
                ? _value.standards
                : standards // ignore: cast_nullable_to_non_nullable
                      as String?,
            performanceStandards: freezed == performanceStandards
                ? _value.performanceStandards
                : performanceStandards // ignore: cast_nullable_to_non_nullable
                      as String?,
            learningCompetencies: freezed == learningCompetencies
                ? _value.learningCompetencies
                : learningCompetencies // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            objectives: freezed == objectives
                ? _value.objectives
                : objectives // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            contentDetails: freezed == contentDetails
                ? _value.contentDetails
                : contentDetails // ignore: cast_nullable_to_non_nullable
                      as String?,
            integration: freezed == integration
                ? _value.integration
                : integration // ignore: cast_nullable_to_non_nullable
                      as CurriculumIntegration?,
          )
          as $Val,
    );
  }

  /// Create a copy of CurriculumContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CurriculumIntegrationCopyWith<$Res>? get integration {
    if (_value.integration == null) {
      return null;
    }

    return $CurriculumIntegrationCopyWith<$Res>(_value.integration!, (value) {
      return _then(_value.copyWith(integration: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CurriculumContentImplCopyWith<$Res>
    implements $CurriculumContentCopyWith<$Res> {
  factory _$$CurriculumContentImplCopyWith(
    _$CurriculumContentImpl value,
    $Res Function(_$CurriculumContentImpl) then,
  ) = __$$CurriculumContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? standards,
    String? performanceStandards,
    List<String>? learningCompetencies,
    List<String>? objectives,
    String? contentDetails,
    CurriculumIntegration? integration,
  });

  @override
  $CurriculumIntegrationCopyWith<$Res>? get integration;
}

/// @nodoc
class __$$CurriculumContentImplCopyWithImpl<$Res>
    extends _$CurriculumContentCopyWithImpl<$Res, _$CurriculumContentImpl>
    implements _$$CurriculumContentImplCopyWith<$Res> {
  __$$CurriculumContentImplCopyWithImpl(
    _$CurriculumContentImpl _value,
    $Res Function(_$CurriculumContentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CurriculumContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? standards = freezed,
    Object? performanceStandards = freezed,
    Object? learningCompetencies = freezed,
    Object? objectives = freezed,
    Object? contentDetails = freezed,
    Object? integration = freezed,
  }) {
    return _then(
      _$CurriculumContentImpl(
        standards: freezed == standards
            ? _value.standards
            : standards // ignore: cast_nullable_to_non_nullable
                  as String?,
        performanceStandards: freezed == performanceStandards
            ? _value.performanceStandards
            : performanceStandards // ignore: cast_nullable_to_non_nullable
                  as String?,
        learningCompetencies: freezed == learningCompetencies
            ? _value._learningCompetencies
            : learningCompetencies // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        objectives: freezed == objectives
            ? _value._objectives
            : objectives // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        contentDetails: freezed == contentDetails
            ? _value.contentDetails
            : contentDetails // ignore: cast_nullable_to_non_nullable
                  as String?,
        integration: freezed == integration
            ? _value.integration
            : integration // ignore: cast_nullable_to_non_nullable
                  as CurriculumIntegration?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CurriculumContentImpl implements _CurriculumContent {
  const _$CurriculumContentImpl({
    this.standards,
    this.performanceStandards,
    final List<String>? learningCompetencies,
    final List<String>? objectives,
    this.contentDetails,
    this.integration,
  }) : _learningCompetencies = learningCompetencies,
       _objectives = objectives;

  factory _$CurriculumContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CurriculumContentImplFromJson(json);

  @override
  final String? standards;
  @override
  final String? performanceStandards;
  final List<String>? _learningCompetencies;
  @override
  List<String>? get learningCompetencies {
    final value = _learningCompetencies;
    if (value == null) return null;
    if (_learningCompetencies is EqualUnmodifiableListView)
      return _learningCompetencies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _objectives;
  @override
  List<String>? get objectives {
    final value = _objectives;
    if (value == null) return null;
    if (_objectives is EqualUnmodifiableListView) return _objectives;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? contentDetails;
  @override
  final CurriculumIntegration? integration;

  @override
  String toString() {
    return 'CurriculumContent(standards: $standards, performanceStandards: $performanceStandards, learningCompetencies: $learningCompetencies, objectives: $objectives, contentDetails: $contentDetails, integration: $integration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurriculumContentImpl &&
            (identical(other.standards, standards) ||
                other.standards == standards) &&
            (identical(other.performanceStandards, performanceStandards) ||
                other.performanceStandards == performanceStandards) &&
            const DeepCollectionEquality().equals(
              other._learningCompetencies,
              _learningCompetencies,
            ) &&
            const DeepCollectionEquality().equals(
              other._objectives,
              _objectives,
            ) &&
            (identical(other.contentDetails, contentDetails) ||
                other.contentDetails == contentDetails) &&
            (identical(other.integration, integration) ||
                other.integration == integration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    standards,
    performanceStandards,
    const DeepCollectionEquality().hash(_learningCompetencies),
    const DeepCollectionEquality().hash(_objectives),
    contentDetails,
    integration,
  );

  /// Create a copy of CurriculumContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CurriculumContentImplCopyWith<_$CurriculumContentImpl> get copyWith =>
      __$$CurriculumContentImplCopyWithImpl<_$CurriculumContentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CurriculumContentImplToJson(this);
  }
}

abstract class _CurriculumContent implements CurriculumContent {
  const factory _CurriculumContent({
    final String? standards,
    final String? performanceStandards,
    final List<String>? learningCompetencies,
    final List<String>? objectives,
    final String? contentDetails,
    final CurriculumIntegration? integration,
  }) = _$CurriculumContentImpl;

  factory _CurriculumContent.fromJson(Map<String, dynamic> json) =
      _$CurriculumContentImpl.fromJson;

  @override
  String? get standards;
  @override
  String? get performanceStandards;
  @override
  List<String>? get learningCompetencies;
  @override
  List<String>? get objectives;
  @override
  String? get contentDetails;
  @override
  CurriculumIntegration? get integration;

  /// Create a copy of CurriculumContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CurriculumContentImplCopyWith<_$CurriculumContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
