import 'package:freezed_annotation/freezed_annotation.dart';

part 'ar_payload.freezed.dart';
part 'ar_payload.g.dart';

@freezed
class ARPayload with _$ARPayload {
  const factory ARPayload({
    required int modelIndex,
    required String detectionMode, // 'marker' | 'surface'
    required String anchorHint,
    required List<String> lessonSteps,
    String? markerImage,
    String? title,
    String? subtitle,
    String? description,
    List<String>? keyIdeas,
    List<String>? historicalImpact,
  }) = _ARPayload;

  factory ARPayload.fromJson(Map<String, dynamic> json) =>
      _$ARPayloadFromJson(json);
}
