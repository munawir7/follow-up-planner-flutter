import '../entities/follow_up_call.dart';

abstract class FollowUpRepository {
  // Fetch all scheduled calls.
  Future<List<FollowUpCall>> getAllCalls();

  // Add a new call.
  Future<void> addCall(FollowUpCall call);

  // Update an existing call.
  Future<void> updateCall(FollowUpCall call);

  // Delete a call using its ID.
  Future<void> deleteCall(String id);

  // Replace the complete call schedule.
  Future<void> replaceAllCalls(List<FollowUpCall> calls);

  // Fetch all blocked dates.
  Future<Set<String>> getBlockedDates();

  // Block a date.
  Future<void> blockDate(String dateKey);

  // Unblock a date.
  Future<void> unblockDate(String dateKey);

  // Replace all blocked dates.
  Future<void> replaceBlockedDates(Set<String> dateKeys);

  Future<void> replaceSchedule({
    required List<FollowUpCall> calls,
    required Set<String> blockedDateKeys,
  });
}
