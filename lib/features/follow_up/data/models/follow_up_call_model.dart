import 'package:follow_up_planner/domain/entities/follow_up_call.dart';

class FollowUpCallModel extends FollowUpCall {
  const FollowUpCallModel({
    required super.id,
    required super.leadName,
    required super.phoneNumber,
    required super.priority,
    required super.dealValuePaise,
    required super.requestedAt,
    required super.scheduledAt,
    required super.createdAt,
  });

  factory FollowUpCallModel.fromEntity(FollowUpCall call) {
    return FollowUpCallModel(
      id: call.id,
      leadName: call.leadName,
      phoneNumber: call.phoneNumber,
      priority: call.priority,
      dealValuePaise: call.dealValuePaise,
      requestedAt: call.requestedAt,
      scheduledAt: call.scheduledAt,
      createdAt: call.createdAt,
    );
  }

  factory FollowUpCallModel.fromMap(Map<String, dynamic> map) {
    return FollowUpCallModel(
      id: map['id'] as String,
      leadName: map['lead_name'] as String,
      phoneNumber: map['phone_number'] as String,
      priority: CallPriority.values.byName(map['priority'] as String),
      dealValuePaise: map['deal_value_paise'] as int,
      requestedAt: DateTime.parse(map['requested_at'] as String),
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lead_name': leadName,
      'phone_number': phoneNumber,
      'priority': priority.name,
      'deal_value_paise': dealValuePaise,
      'requested_at': requestedAt.toIso8601String(),
      'scheduled_at': scheduledAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
