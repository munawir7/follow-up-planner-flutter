import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

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
      requestedAt: _decodeIstWallClock(map['requested_at'] as String),
      scheduledAt: _decodeIstWallClock(map['scheduled_at'] as String),
      createdAt: _decodeIstWallClock(map['created_at'] as String),
    );
  }

  static String _encodeIstWallClock(DateTime dateTime) {
    return DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    ).toIso8601String().replaceFirst('Z', '');
  }

  static DateTime _decodeIstWallClock(String value) {
    final parsed = DateTime.parse(value);

    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lead_name': leadName,
      'phone_number': phoneNumber,
      'priority': priority.name,
      'deal_value_paise': dealValuePaise,
      'requested_at': _encodeIstWallClock(requestedAt),
      'scheduled_at': _encodeIstWallClock(scheduledAt),
      'created_at': _encodeIstWallClock(createdAt),
    };
  }
}
