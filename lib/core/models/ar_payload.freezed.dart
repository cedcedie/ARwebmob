// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ar_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ARPayload _$ARPayloadFromJson(Map<String, dynamic> json) {
  return _ARPayload.fromJson(json);
}

/// @nodoc
mixin _$ARPayload {
  int get modelIndex => throw _privateConstructorUsedError;
  String get detectionMode =>
      throw _privateConstructorUsedError; // 'marker' | 'surface'
  String get anchorHint => throw _privateConstructorUsedError;
  List<String> get lessonSteps => throw _privateConstructorUsedError;
  String? get markerImage => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String>? get keyIdeas => throw _privateConstructorUsedError;
  List<String>? get historicalImpact => throw _privateConstructorUsedError;

  /// Serializes this ARPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ARPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ARPayloadCopyWith<ARPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ARPayloadCopyWith<$Res> {
  factory $ARPayloadCopyWith(ARPayload value, $Res Function(ARPayload) then) =
      _$ARPayloadCopyWithImpl<$Res, ARPayload>;
  @useResult
  $Res call({
    int modelIndex,
    String detectionMode,
    String anchorHint,
    List<String> lessonSteps,
    String? markerImage,
    String? title,
    String? subtitle,
    String? description,
    List<String>? keyIdeas,
    List<String>? historicalImpact,
  });
}

/// @nodoc
class _$ARPayloadCopyWithImpl<$Res, $Val extends ARPayload>
    implements $ARPayloadCopyWith<$Res> {
  _$ARPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ARPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelIndex = null,
    Object? detectionMode = null,
    Object? anchorHint = null,
    Object? lessonSteps = null,
    Object? markerImage = freezed,
    Object? title = freezed,
    Object? subtitle = freezed,
    Object? description = freezed,
    Object? keyIdeas = freezed,
    Object? historicalImpact = freezed,
  }) {
    return _then(
      _value.copyWith(
            modelIndex: null == modelIndex
                ? _value.modelIndex
                : modelIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            detectionMode: null == detectionMode
                ? _value.detectionMode
                : detectionMode // ignore: cast_nullable_to_non_nullable
                      as String,
            anchorHint: null == anchorHint
                ? _value.anchorHint
                : anchorHint // ignore: cast_nullable_to_non_nullable
                      as String,
            lessonSteps: null == lessonSteps
                ? _value.lessonSteps
                : lessonSteps // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            markerImage: freezed == markerImage
                ? _value.markerImage
                : markerImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            keyIdeas: freezed == keyIdeas
                ? _value.keyIdeas
                : keyIdeas // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            historicalImpact: freezed == historicalImpact
                ? _value.historicalImpact
                : historicalImpact // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ARPayloadImplCopyWith<$Res>
    implements $ARPayloadCopyWith<$Res> {
  factory _$$ARPayloadImplCopyWith(
    _$ARPayloadImpl value,
    $Res Function(_$ARPayloadImpl) then,
  ) = __$$ARPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int modelIndex,
    String detectionMode,
    String anchorHint,
    List<String> lessonSteps,
    String? markerImage,
    String? title,
    String? subtitle,
    String? description,
    List<String>? keyIdeas,
    List<String>? historicalImpact,
  });
}

/// @nodoc
class __$$ARPayloadImplCopyWithImpl<$Res>
    extends _$ARPayloadCopyWithImpl<$Res, _$ARPayloadImpl>
    implements _$$ARPayloadImplCopyWith<$Res> {
  __$$ARPayloadImplCopyWithImpl(
    _$ARPayloadImpl _value,
    $Res Function(_$ARPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ARPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelIndex = null,
    Object? detectionMode = null,
    Object? anchorHint = null,
    Object? lessonSteps = null,
    Object? markerImage = freezed,
    Object? title = freezed,
    Object? subtitle = freezed,
    Object? description = freezed,
    Object? keyIdeas = freezed,
    Object? historicalImpact = freezed,
  }) {
    return _then(
      _$ARPayloadImpl(
        modelIndex: null == modelIndex
            ? _value.modelIndex
            : modelIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        detectionMode: null == detectionMode
            ? _value.detectionMode
            : detectionMode // ignore: cast_nullable_to_non_nullable
                  as String,
        anchorHint: null == anchorHint
            ? _value.anchorHint
            : anchorHint // ignore: cast_nullable_to_non_nullable
                  as String,
        lessonSteps: null == lessonSteps
            ? _value._lessonSteps
            : lessonSteps // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        markerImage: freezed == markerImage
            ? _value.markerImage
            : markerImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        keyIdeas: freezed == keyIdeas
            ? _value._keyIdeas
            : keyIdeas // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        historicalImpact: freezed == historicalImpact
            ? _value._historicalImpact
            : historicalImpact // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ARPayloadImpl implements _ARPayload {
  const _$ARPayloadImpl({
    required this.modelIndex,
    required this.detectionMode,
    required this.anchorHint,
    required final List<String> lessonSteps,
    this.markerImage,
    this.title,
    this.subtitle,
    this.description,
    final List<String>? keyIdeas,
    final List<String>? historicalImpact,
  }) : _lessonSteps = lessonSteps,
       _keyIdeas = keyIdeas,
       _historicalImpact = historicalImpact;

  factory _$ARPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ARPayloadImplFromJson(json);

  @override
  final int modelIndex;
  @override
  final String detectionMode;
  // 'marker' | 'surface'
  @override
  final String anchorHint;
  final List<String> _lessonSteps;
  @override
  List<String> get lessonSteps {
    if (_lessonSteps is EqualUnmodifiableListView) return _lessonSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lessonSteps);
  }

  @override
  final String? markerImage;
  @override
  final String? title;
  @override
  final String? subtitle;
  @override
  final String? description;
  final List<String>? _keyIdeas;
  @override
  List<String>? get keyIdeas {
    final value = _keyIdeas;
    if (value == null) return null;
    if (_keyIdeas is EqualUnmodifiableListView) return _keyIdeas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _historicalImpact;
  @override
  List<String>? get historicalImpact {
    final value = _historicalImpact;
    if (value == null) return null;
    if (_historicalImpact is EqualUnmodifiableListView)
      return _historicalImpact;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ARPayload(modelIndex: $modelIndex, detectionMode: $detectionMode, anchorHint: $anchorHint, lessonSteps: $lessonSteps, markerImage: $markerImage, title: $title, subtitle: $subtitle, description: $description, keyIdeas: $keyIdeas, historicalImpact: $historicalImpact)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ARPayloadImpl &&
            (identical(other.modelIndex, modelIndex) ||
                other.modelIndex == modelIndex) &&
            (identical(other.detectionMode, detectionMode) ||
                other.detectionMode == detectionMode) &&
            (identical(other.anchorHint, anchorHint) ||
                other.anchorHint == anchorHint) &&
            const DeepCollectionEquality().equals(
              other._lessonSteps,
              _lessonSteps,
            ) &&
            (identical(other.markerImage, markerImage) ||
                other.markerImage == markerImage) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._keyIdeas, _keyIdeas) &&
            const DeepCollectionEquality().equals(
              other._historicalImpact,
              _historicalImpact,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    modelIndex,
    detectionMode,
    anchorHint,
    const DeepCollectionEquality().hash(_lessonSteps),
    markerImage,
    title,
    subtitle,
    description,
    const DeepCollectionEquality().hash(_keyIdeas),
    const DeepCollectionEquality().hash(_historicalImpact),
  );

  /// Create a copy of ARPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ARPayloadImplCopyWith<_$ARPayloadImpl> get copyWith =>
      __$$ARPayloadImplCopyWithImpl<_$ARPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ARPayloadImplToJson(this);
  }
}

abstract class _ARPayload implements ARPayload {
  const factory _ARPayload({
    required final int modelIndex,
    required final String detectionMode,
    required final String anchorHint,
    required final List<String> lessonSteps,
    final String? markerImage,
    final String? title,
    final String? subtitle,
    final String? description,
    final List<String>? keyIdeas,
    final List<String>? historicalImpact,
  }) = _$ARPayloadImpl;

  factory _ARPayload.fromJson(Map<String, dynamic> json) =
      _$ARPayloadImpl.fromJson;

  @override
  int get modelIndex;
  @override
  String get detectionMode; // 'marker' | 'surface'
  @override
  String get anchorHint;
  @override
  List<String> get lessonSteps;
  @override
  String? get markerImage;
  @override
  String? get title;
  @override
  String? get subtitle;
  @override
  String? get description;
  @override
  List<String>? get keyIdeas;
  @override
  List<String>? get historicalImpact;

  /// Create a copy of ARPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ARPayloadImplCopyWith<_$ARPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
