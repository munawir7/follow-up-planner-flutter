import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:follow_up_planner/core/utils/ist_date_time.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/presentation/providers/follow_up_provider.dart';
import 'package:follow_up_planner/features/follow_up/presentation/screens/add_call_screen.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.date});

  final DateTime date;

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowUpProvider>();

    final dailyCalls = provider.calls.where((call) {
      return call.scheduledAt.year == date.year &&
          call.scheduledAt.month == date.month &&
          call.scheduledAt.day == date.day;
    }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final isBlocked = provider.blockedDateKeys.contains(
      IstDateTime.dateKey(date),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Day Details')),

      body: Column(
        children: [
          // Date and summary.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day} ${_monthName(date.month)} ${date.year}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${dailyCalls.length} calls scheduled',
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Blocked day information.
          if (isBlocked)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This day is blocked.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Scheduled calls.
          Expanded(
            child: dailyCalls.isEmpty
                ? const Center(
                    child: Text(
                      'No calls scheduled for this day.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dailyCalls.length,

                    itemBuilder: (context, index) {
                      return _buildCallCard(
                        context,
                        dailyCalls[index],
                        provider.isSaving,
                      );
                    },
                  ),
          ),

          // Block day button.
          if (!isBlocked)
            Padding(
              padding: const EdgeInsets.all(16),

              child: SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _confirmBlockDay(context),

                  icon: const Icon(Icons.block),

                  label: const Text('Block This Day'),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Individual call card.
  Widget _buildCallCard(
    BuildContext context,
    FollowUpCall call,
    bool isSaving,
  ) {
    final priorityColor = switch (call.priority) {
      CallPriority.hot => Colors.red,
      CallPriority.warm => Colors.orange,
      CallPriority.cold => Colors.blue,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 85,

                  child: Text(
                    _formatTime(call.scheduledAt),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Container(
                  width: 4,
                  height: 55,

                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        call.leadName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        call.phoneNumber,
                        style: const TextStyle(color: Colors.grey),
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

            const Divider(height: 24),

            // Edit and Delete actions.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,

              children: [
                TextButton.icon(
                  onPressed: isSaving ? null : () => _editCall(context, call),

                  icon: const Icon(Icons.edit, size: 18),

                  label: const Text('Edit'),
                ),

                const SizedBox(width: 8),

                TextButton.icon(
                  onPressed: isSaving
                      ? null
                      : () => _confirmDeleteCall(context, call),

                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),

                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Open the AddCallScreen in edit mode.
  void _editCall(BuildContext context, FollowUpCall call) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddCallScreen(existingCall: call);
        },
      ),
    );
  }

  // Show delete confirmation.
  Future<void> _confirmDeleteCall(
    BuildContext context,
    FollowUpCall call,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Follow-Up Call?'),

          content: Text(
            'Are you sure you want to delete '
            'the call for ${call.leadName}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    final provider = context.read<FollowUpProvider>();

    final success = await provider.deleteCall(call.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Follow-up call deleted successfully!'
              : provider.errorMessage ?? 'Unable to delete the call.',
        ),

        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // Confirm and block the selected day.
  Future<void> _confirmBlockDay(BuildContext context) async {
    final shouldBlock = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block This Day?'),

          content: const Text(
            'All calls scheduled on this day will be moved '
            'to the next available working days.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),

              child: const Text('Block Day'),
            ),
          ],
        );
      },
    );

    if (shouldBlock != true || !context.mounted) {
      return;
    }

    final provider = context.read<FollowUpProvider>();

    final result = await provider.blockDay(date);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null
              ? 'Day blocked! ${result.movedCalls.length} calls rescheduled.'
              : provider.errorMessage ?? 'Unable to block this day.',
        ),

        backgroundColor: result != null ? Colors.green : Colors.red,
      ),
    );
  }
}
