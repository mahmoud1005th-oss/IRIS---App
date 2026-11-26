import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:iris_app/features/ui/hologram_ui.dart';
import 'package:iris_app/core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تشغيل المهام الدورية في الخلفية (لحذف الملفات القديمة)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    "iris_cleanup", "cleanupTask",
    frequency: Duration(hours: 12),
  );

  runApp(const IrisApp());
}

// الكود اللي بيشتغل في الخلفية
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "cleanupTask") {
      await DatabaseHelper.instance.deleteExpiredData();
    }
    return Future.value(true);
  });
}

class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I.R.I.S',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HologramUI(), // شاشة اللايف الهولوغرامية
    );
  }
}
