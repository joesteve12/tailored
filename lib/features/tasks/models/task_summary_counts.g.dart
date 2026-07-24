// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_summary_counts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskSummaryCountsImpl _$$TaskSummaryCountsImplFromJson(
        Map<String, dynamic> json) =>
    _$TaskSummaryCountsImpl(
      overdue: (json['overdue'] as num).toInt(),
      dueToday: (json['due_today'] as num).toInt(),
      dueTomorrow: (json['due_tomorrow'] as num).toInt(),
    );

Map<String, dynamic> _$$TaskSummaryCountsImplToJson(
        _$TaskSummaryCountsImpl instance) =>
    <String, dynamic>{
      'overdue': instance.overdue,
      'due_today': instance.dueToday,
      'due_tomorrow': instance.dueTomorrow,
    };
