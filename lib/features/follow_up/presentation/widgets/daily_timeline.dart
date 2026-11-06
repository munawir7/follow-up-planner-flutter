import 'package:flutter/material.dart';

import 'package:follow_up_planner/core/constants/app_constants.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/presentation/screens/add_call_screen.dart';

import '../../domain/services/scheduling_slot_generator.dart';

class DailyTimeline extends StatelessWidget {
  const DailyTimeline({super.key, required this.date, required this.calls});

  final DateTime date;
  final List<FollowUpCall> calls;

  @override
  Widget build(BuildContext context) {
    // Generate all valid slots for the selected day.
    final slots = SchedulingSlotGenerator.generateSlotsForDay(date);

    // Handle days with no available slots.
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No available time slots for this day.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Build timeline items dynamically.
    final timelineItems = <Widget>[];
    var lunchBreakInserted = false;

    for (final slot in slots) {
      // Insert lunch break before the first slot at or after lunch end.
      if (!lunchBreakInserted && slot.hour >= AppConstants.lunchEndHour) {
        timelineItems.add(_buildLunchBreak());
        lunchBreakInserted = true;
      }

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

      timelineItems.add(
        _buildTimeSlot(context: context, slot: slot, call: scheduledCall),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: timelineItems,
    );
  }

  Widget _buildTimeSlot({
    required BuildContext context,
    required DateTime slot,
    required FollowUpCall? call,
  }) {
    final time =
        '${slot.hour.toString().padLeft(2, '0')}:'
        '${slot.minute.toString().padLeft(2, '0')}';

    // Available time slot.
    if (call == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCallScreen(initialDateTime: slot),
            ),
          );
        },
        child: Container(
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
              const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('Available', style: TextStyle(color: Colors.grey)),
            ],
          ),
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
