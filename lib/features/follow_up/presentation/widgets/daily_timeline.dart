import 'package:flutter/material.dart';

import 'package:follow_up_planner/domain/entities/follow_up_call.dart';

import '../../domain/services/scheduling_slot_generator.dart';

class DailyTimeline extends StatelessWidget {
  const DailyTimeline({super.key, required this.date, required this.calls});

  final DateTime date;
  final List<FollowUpCall> calls;

  @override
  Widget build(BuildContext context) {
    // Generate all valid 30-minute slots.
    final slots = SchedulingSlotGenerator.generateSlotsForDay(date);

    return ListView.builder(
      // Extra bottom padding prevents the FAB from covering the last slot.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),

      itemCount: slots.length + 1,

      itemBuilder: (context, index) {
        // Insert lunch break after the seventh slot.
        if (index == 7) {
          return _buildLunchBreak();
        }

        final slotIndex = index < 7 ? index : index - 1;
        final slot = slots[slotIndex];

        // Find whether this slot contains a scheduled call.
        FollowUpCall? scheduledCall;

        for (final call in calls) {
          if (call.scheduledAt.year == slot.year &&
              call.scheduledAt.month == slot.month &&
              call.scheduledAt.day == slot.day &&
              call.scheduledAt.hour == slot.hour &&
              call.scheduledAt.minute == slot.minute) {
            scheduledCall = call;
            break;
          }
        }

        return _buildTimeSlot(slot: slot, call: scheduledCall);
      },
    );
  }

  Widget _buildTimeSlot({required DateTime slot, required FollowUpCall? call}) {
    final time =
        '${slot.hour.toString().padLeft(2, '0')}:'
        '${slot.minute.toString().padLeft(2, '0')}';

    // Available time slot.
    if (call == null) {
      return Container(
        height: 65,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 65,
              child: Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.add_circle_outline, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('Available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Get priority color.
    final priorityColor = switch (call.priority) {
      CallPriority.hot => Colors.red,
      CallPriority.warm => Colors.orange,
      CallPriority.cold => Colors.blue,
    };

    // Scheduled call slot.
    return Container(
      height: 75,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  call.leadName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  call.phoneNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            call.priority.name.toUpperCase(),
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Lunch break widget.
  Widget _buildLunchBreak() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 17, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Lunch Break  •  01:00 PM – 02:00 PM',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
