import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:follow_up_planner/core/utils/ist_date_time.dart';

import 'day_detail_screen.dart';
import '../providers/follow_up_provider.dart';
import '../widgets/daily_timeline.dart';
import '../widgets/summary_bar.dart';
import 'add_call_screen.dart';

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key});

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _selectedDate;
  @override
  void initState() {
    super.initState();

    final today = IstDateTime.nowIst();

    final todayDate = DateTime.utc(today.year, today.month, today.day);

    _selectedDate = IstDateTime.isWorkingDay(todayDate)
        ? todayDate
        : IstDateTime.nextWorkingDay(todayDate);
  }

  // Get Monday of the selected week.
  DateTime get _weekStart {
    return _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - DateTime.monday),
    );
  }

  // Get the next Monday (exclusive end of the week).
  DateTime get _weekEnd {
    return _weekStart.add(const Duration(days: 7));
  }

  // Get Monday to Saturday.
  List<DateTime> get _weekDays {
    return List.generate(6, (index) => _weekStart.add(Duration(days: index)));
  }

  // Navigate between weeks.
  void _changeWeek(int weeks) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: weeks * 7));
    });
  }

  // Select a particular day.
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

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

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowUpProvider>();

    // Get calls scheduled for the selected day.
    final dailyCalls = provider.calls.where((call) {
      return call.scheduledAt.year == _selectedDate.year &&
          call.scheduledAt.month == _selectedDate.month &&
          call.scheduledAt.day == _selectedDate.day;
    }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Get all calls scheduled during the selected week.
    // Monday is included, next Monday is excluded.
    final weeklyCalls = provider.calls.where((call) {
      return !call.scheduledAt.isBefore(_weekStart) &&
          call.scheduledAt.isBefore(_weekEnd);
    }).toList();

    final dateKey = IstDateTime.dateKey(_selectedDate);
    final isBlocked = provider.blockedDateKeys.contains(dateKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Follow-Up Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: provider.canUndo && !provider.isSaving
                ? () => provider.undo()
                : null,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: provider.canRedo && !provider.isSaving
                ? () => provider.redo()
                : null,
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week navigation.
          _buildWeekHeader(),

          // Working-day selector.
          _buildDaySelector(),

          const Divider(height: 1),

          // Selected day information.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_dayName(_selectedDate.weekday)}, '
                        '${_selectedDate.day} '
                        '${_monthName(_selectedDate.month)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dailyCalls.length} calls scheduled',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View Day Details',
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DayDetailScreen(date: _selectedDate),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Weekly summary.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SummaryBar(calls: weeklyCalls),
          ),

          const SizedBox(height: 8),

          // Blocked day or call list.
          Expanded(
            child: isBlocked
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 32, color: Colors.redAccent),
                        SizedBox(height: 8),
                        Text(
                          'This day is blocked',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : dailyCalls.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 32,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No calls scheduled',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : DailyTimeline(date: _selectedDate, calls: dailyCalls),
          ),
        ],
      ),

      // Add Call button.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSaving
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCallScreen(),
                  ),
                );
              },
        icon: const Icon(Icons.add),
        label: const Text('Add Call'),
      ),
    );
  }

  // Week navigation header.
  Widget _buildWeekHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${_monthName(_weekStart.month)} ${_weekStart.year}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // Monday to Saturday selector.
  Widget _buildDaySelector() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final date = _weekDays[index];

          final isSelected =
              IstDateTime.dateKey(date) == IstDateTime.dateKey(_selectedDate);

          return GestureDetector(
            onTap: () => _selectDate(date),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
