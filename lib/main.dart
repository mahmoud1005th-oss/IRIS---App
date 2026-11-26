import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'features/ui/onboarding_ui.dart';
import 'features/ui/hologram_ui.dart';
import 'features/ui/admin_ui.dart';
import 'core/services/auth_service.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // محمود هيحط رابط Supabase والمفتاح في core/services/auth_service.dart
  // طالما المفاتيح Placeholder التطبيق هيشتغل عادي من غير تسجيل دخول
  if (supabaseConfigured) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

  // تشغيل المهام الدورية في الخلفية (لحذف الملفات القديمة)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    "iris_cleanup", "cleanupTask",
    frequency: const Duration(hours: 12),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.cyanAccent,
      ),
      home: const AuthGate(), // بيشوف المستخدم مسجل ولا لأ
    );
  }
}

// بوابة الدخول: لو فيه جلسة مسجلة يدخل على طول، غير كده يبدأ من الـ Onboarding
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    if (auth.isSignedIn) {
      return auth.isAdmin() ? const AdminUI() : const HologramUI();
    }
    return const OnboardingUI();
  }
}
