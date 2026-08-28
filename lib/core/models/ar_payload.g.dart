// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ar_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ARPayloadImpl _$$ARPayloadImplFromJson(Map<String, dynamic> json) =>
    _$ARPayloadImpl(
      modelIndex: (json['modelIndex'] as num).toInt(),
      detectionMode: json['detectionMode'] as String,
      anchorHint: json['anchorHint'] as String,
      lessonSteps: (json['lessonSteps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      markerImage: json['markerImage'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      keyIdeas: (json['keyIdeas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      historicalImpact: (json['historicalImpact'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ARPayloadImplToJson(_$ARPayloadImpl instance) =>
    <String, dynamic>{
      'modelIndex': instance.modelIndex,
      'detectionMode': instance.detectionMode,
      'anchorHint': instance.anchorHint,
      'lessonSteps': instance.lessonSteps,
      'markerImage': instance.markerImage,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'description': instance.description,
      'keyIdeas': instance.keyIdeas,
      'historicalImpact': instance.historicalImpact,
    };
