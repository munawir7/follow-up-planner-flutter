import 'package:flutter/material.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

extension CallPriorityExtensions on CallPriority {
  Color get color {
    return switch (this) {
      CallPriority.hot => Colors.red,
      CallPriority.warm => Colors.orange,
      CallPriority.cold => Colors.blue,
    };
  }

  int get sortOrder {
    return switch (this) {
      CallPriority.hot => 0,
      CallPriority.warm => 1,
      CallPriority.cold => 2,
    };
  }
}
