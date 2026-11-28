import 'package:supabase_flutter/supabase_flutter.dart';

// محمود هيحط رابط Supabase والمفتاح هنا
const String supabaseUrl = 'https://dqvmuemvfngpfjkptvjr.supabase.co';
const String supabaseAnonKey = 'sb_publishable_NZT67s5FuSLmvr70TGKefw_UFpxip0x';

// الرابط اللي المتصفح بيرجّع بيه المستخدم للتطبيق بعد الدخول بجوجل/جيت هاب
const String kAuthRedirect = 'iris://login-callback';

bool get supabaseConfigured =>
    !supabaseUrl.contains('YOUR_') && !supabaseAnonKey.contains('YOUR_');

class AuthService {
  static const String adminEmail = "mahmoud1005th@gmail.com";

  GoTrueClient? get _auth {
    if (!supabaseConfigured) return null;
    try {
      return Supabase.instance.client.auth;
    } catch (_) {
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.google, redirectTo: kAuthRedirect);
  }

  Future<void> signInWithMicrosoft() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.azure, redirectTo: kAuthRedirect);
  }

  Future<void> signInWithApple() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.apple, redirectTo: kAuthRedirect);
  }

  Future<void> signInWithGitHub() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.github, redirectTo: kAuthRedirect);
  }

  // تسجيل بالإيميل والباسورد - بيرجع true لو نجح
  Future<bool> signInWithPassword(String email, String password) async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      final res =
          await auth.signInWithPassword(email: email, password: password);
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  // حساب جديد بالإيميل والباسورد
  Future<bool> signUpWithPassword(String email, String password) async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      final res = await auth.signUp(email: email, password: password);
      return res.user != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }

  // إعادة تعيين كلمة السر بالإيميل. بيرجع false لو السيرفر مش متوصل
  Future<bool> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      await auth.resetPasswordForEmail(email, redirectTo: kAuthRedirect);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isSignedIn {
    try {
      return _auth?.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  bool isAdmin() {
    try {
      return _auth?.currentUser?.email == adminEmail;
    } catch (_) {
      return false;
    }
  }

  // إيميل الحساب الحالي لو موجود (بنستخدمه في ترحيب "Welcome back" بعد المسح)
  String? get currentEmail {
    try {
      return _auth?.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  String? get displayName {
    try {
      final m = _auth?.currentUser?.userMetadata;
      return (m?['full_name'] ?? m?['name']) as String?;
    } catch (_) {
      return null;
    }
  }
}
