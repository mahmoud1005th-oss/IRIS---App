import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/ui/intro_splash.dart';
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

// بوابة الدخول: لو فيه جلسة مسجلة يدخل على طول، غير كده يبدأ بأنيميشن البداية
// في أول تشغيل فقط، وبعدها يفتح على المحادثة مباشرة (V3.1)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String kIntroSeenKey = 'intro_seen';

  Future<bool> _introSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kIntroSeenKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    if (auth.isSignedIn) {
      return auth.isAdmin() ? const AdminUI() : const HologramUI();
    }
    // وضع الاختبار: الأنيميشن بيظهر كل تشغيل. لما محمود يثبت الشكل النهائي
    // نرجع kIntroFirstLaunchOnly = true فيشتغل أول مرة بس
    if (!kIntroFirstLaunchOnly) {
      return const IntroSplashScreen();
    }
    // أنيميشن البداية بيظهر أول مرة بس؛ من تاني مرة يفتح على المحادثة على طول
    return FutureBuilder<bool>(
      future: _introSeen(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(backgroundColor: Colors.black);
        }
        return snap.data! ? const HologramUI() : const IntroSplashScreen();
      },
    );
  }
}
