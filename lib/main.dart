import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/follow_up/data/datasources/local/app_database.dart';
import 'features/follow_up/data/datasources/local/follow_up_local_data_source.dart';
import 'features/follow_up/data/repositories/follow_up_repository_impl.dart';
import 'features/follow_up/presentation/providers/follow_up_provider.dart';
import 'domain/repositories/follow_up_repository.dart';
import 'features/follow_up/presentation/screens/week_view_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Initialize the local database.
  final appDatabase = AppDatabase.instance;

  // Step 2: Create the local data source.
  final localDataSource = FollowUpLocalDataSource(appDatabase: appDatabase);

  // Step 3: Create the repository.
  final repository = FollowUpRepositoryImpl(localDataSource: localDataSource);

  // Step 4: Start the application.
  runApp(FollowUpPlannerApp(repository: repository));
}

class FollowUpPlannerApp extends StatelessWidget {
  const FollowUpPlannerApp({super.key, required this.repository});

  final FollowUpRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FollowUpProvider(repository: repository)..loadSchedule(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Follow-Up Planner',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E293B),
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: const WeekViewScreen(),
      ),
    );
  }
}

// Temporary home screen.
// We will replace this with the actual Week View screen.
class FollowUpHomeScreen extends StatelessWidget {
  const FollowUpHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Follow-Up Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<FollowUpProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text(provider.errorMessage!, textAlign: TextAlign.center),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 70,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Follow-Up Planner!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total scheduled calls: ${provider.calls.length}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
