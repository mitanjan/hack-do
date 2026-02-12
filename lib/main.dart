import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'services/task_service.dart';
import 'services/sync_service.dart';
import 'theme/matrix_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(TaskAdapter());

  final taskService = TaskService();
  await taskService.init();

  final deviceName = Platform.localHostname;
  final syncService = SyncService(
    taskService: taskService,
    deviceName: deviceName,
  );
  await syncService.start();

  runApp(HackDoApp(taskService: taskService, syncService: syncService));
}

class HackDoApp extends StatefulWidget {
  final TaskService taskService;
  final SyncService syncService;

  const HackDoApp({
    super.key,
    required this.taskService,
    required this.syncService,
  });

  @override
  State<HackDoApp> createState() => _HackDoAppState();
}

class _HackDoAppState extends State<HackDoApp> {
  @override
  void dispose() {
    widget.syncService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HACK-DO',
      debugShowCheckedModeBanner: false,
      theme: MatrixTheme.darkTheme,
      home: HomeScreen(
        taskService: widget.taskService,
        syncService: widget.syncService,
      ),
    );
  }
}
