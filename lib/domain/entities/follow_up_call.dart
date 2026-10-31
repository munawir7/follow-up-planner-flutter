enum CallPriority { hot, warm, cold }

class FollowUpCall {
  final String id;
  final String leadName;
  final String phoneNumber;
  final CallPriority priority;
  final int dealValuePaise;
  final DateTime requestedAt;
  final DateTime scheduledAt;
  final DateTime createdAt;

  const FollowUpCall({
    required this.id,
    required this.leadName,
    required this.phoneNumber,
    required this.priority,
    required this.dealValuePaise,
    required this.requestedAt,
    required this.scheduledAt,
    required this.createdAt,
  });

  FollowUpCall copyWith({
    String? id,
    String? leadName,
    String? phoneNumber,
    CallPriority? priority,
    int? dealValuePaise,
    DateTime? requestedAt,
    DateTime? scheduledAt,
    DateTime? createdAt,
  }) {
    return FollowUpCall(
      id: id ?? this.id,
      leadName: leadName ?? this.leadName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      priority: priority ?? this.priority,
      dealValuePaise: dealValuePaise ?? this.dealValuePaise,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
