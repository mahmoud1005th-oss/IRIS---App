import 'package:supabase_flutter/supabase_flutter.dart';

// محمود هيحط رابط Supabase والمفتاح هنا
const String supabaseUrl = 'https://YOUR_SUPABASE_URL.supabase.co';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

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
    await auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithMicrosoft() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.azure);
  }

  Future<void> signInWithApple() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signInWithGitHub() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signInWithOAuth(OAuthProvider.github);
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
}
