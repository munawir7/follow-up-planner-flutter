import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:follow_up_planner/features/follow_up/data/datasources/local/app_database.dart';
import 'package:follow_up_planner/features/follow_up/data/datasources/local/follow_up_local_data_source.dart';
import 'package:follow_up_planner/features/follow_up/data/repositories/follow_up_repository_impl.dart';
import 'package:follow_up_planner/features/follow_up/domain/repositories/follow_up_repository.dart';
import 'package:follow_up_planner/features/follow_up/presentation/providers/follow_up_provider.dart';
import 'package:follow_up_planner/features/follow_up/presentation/screens/week_view_screen.dart';
import 'package:follow_up_planner/core/utils/ist_date_time.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDatabase = AppDatabase.instance;

  final localDataSource = FollowUpLocalDataSource(appDatabase: appDatabase);

  final repository = FollowUpRepositoryImpl(localDataSource: localDataSource);

  runApp(FollowUpPlannerApp(repository: repository));
}

class FollowUpPlannerApp extends StatelessWidget {
  final FollowUpRepository repository;
  final DateTime Function() nowProvider;

  const FollowUpPlannerApp({
    super.key,
    required this.repository,
    this.nowProvider = IstDateTime.nowIst,
  });
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FollowUpProvider(repository: repository)..loadSchedule(),
      child: MaterialApp(
        title: 'Follow-Up Planner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
        ),
       home: WeekViewScreen(nowProvider: nowProvider),
      ),
    );
  }
}
