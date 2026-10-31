import 'package:flutter/material.dart';

import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/core/utils/indian_currency_formatter.dart';

class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key, required this.calls});

  final List<FollowUpCall> calls;

  int get totalDealValue {
    return calls.fold(0, (total, call) => total + call.dealValuePaise);
  }

  int get hotCount =>
      calls.where((call) => call.priority == CallPriority.hot).length;

  int get warmCount =>
      calls.where((call) => call.priority == CallPriority.warm).length;

  int get coldCount =>
      calls.where((call) => call.priority == CallPriority.cold).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Summary',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                label: 'Total Calls',
                value: calls.length.toString(),
                icon: Icons.call,
                color: Colors.blue,
              ),
              _buildSummaryItem(
                label: 'Deal Value',
                value: IndianCurrencyFormatter.formatSummary(
                  totalDealValue / 100,
                ),
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
            ],
          ),

          const Divider(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPriorityItem('Hot', hotCount, Colors.red),
              _buildPriorityItem('Warm', warmCount, Colors.orange),
              _buildPriorityItem('Cold', coldCount, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
