import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

class ScheduleDiff {
  final List<FollowUpCall> inserted;
  final List<FollowUpCall> updated;
  final List<String> deletedIds;

  const ScheduleDiff({
    this.inserted = const [],
    this.updated = const [],
    this.deletedIds = const [],
  });

  factory ScheduleDiff.calculate({
    required List<FollowUpCall> previousCalls,
    required List<FollowUpCall> updatedCalls,
  }) {
    final previousById = {for (final call in previousCalls) call.id: call};

    final updatedById = {for (final call in updatedCalls) call.id: call};

    final inserted = updatedCalls
        .where((call) => !previousById.containsKey(call.id))
        .toList();

    final updated = updatedCalls.where((call) {
      final previous = previousById[call.id];

      return previous != null && !_isSameCall(previous, call);
    }).toList();

    final deletedIds = previousCalls
        .where((call) => !updatedById.containsKey(call.id))
        .map((call) => call.id)
        .toList();

    return ScheduleDiff(
      inserted: inserted,
      updated: updated,
      deletedIds: deletedIds,
    );
  }

  static bool _isSameCall(FollowUpCall a, FollowUpCall b) {
    return a.id == b.id &&
        a.leadName == b.leadName &&
        a.phoneNumber == b.phoneNumber &&
        a.priority == b.priority &&
        a.dealValuePaise == b.dealValuePaise &&
        a.requestedAt == b.requestedAt &&
        a.scheduledAt == b.scheduledAt &&
        a.createdAt == b.createdAt;
  }

  bool get isEmpty => inserted.isEmpty && updated.isEmpty && deletedIds.isEmpty;
}
