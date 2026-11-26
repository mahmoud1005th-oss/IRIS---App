import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/auth_service.dart';
import 'hologram_ui.dart';
import 'admin_ui.dart';

class OnboardingUI extends StatefulWidget {
  const OnboardingUI({super.key});
  @override
  State<OnboardingUI> createState() => _OnboardingUIState();
}

class _OnboardingUIState extends State<OnboardingUI> {
  String? gender;
  String language = "ar";
  final auth = AuthService();
  final LocalAuthentication biometricAuth = LocalAuthentication();

  void _authenticateBiometric() async {
    try {
      bool canCheck = await biometricAuth.canCheckBiometrics;
      if (canCheck) {
        bool authenticated = await biometricAuth.authenticate(
          localizedReason: 'جاري مسح شبكية العين للمزامنة...',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated) {
          _goToNextScreen();
        }
      } else {
        _goToNextScreen(); // لو الجهاز مش بيدعم
      }
    } catch (e) {
      _goToNextScreen();
    }
  }

  void _goToNextScreen() {
    if (auth.isAdmin()) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminUI()));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HologramUI(gender: gender, language: language)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("أهلاً بك في نظام I.R.I.S", style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              const Text("اختر اللغة:", style: TextStyle(color: Colors.white)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(value: "ar", groupValue: language, onChanged: (v) => setState(() => language = v!)),
                  const Text("العربية", style: TextStyle(color: Colors.white)),
                  Radio<String>(value: "en", groupValue: language, onChanged: (v) => setState(() => language = v!)),
                  const Text("English", style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 20),
              const Text("اختر جنسك (لتخصيص الصوت والنبرة):", style: TextStyle(color: Colors.white)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => gender = "male"),
                    style: ElevatedButton.styleFrom(backgroundColor: gender == "male" ? Colors.cyanAccent : Colors.grey),
                    child: const Text("ذكر"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => setState(() => gender = "female"),
                    style: ElevatedButton.styleFrom(backgroundColor: gender == "female" ? Colors.cyanAccent : Colors.grey),
                    child: const Text("أنثى"),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (gender != null) ...[
                const Text("سجل دخولك لمزامنة البيانات:", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () { auth.signInWithGoogle(); _authenticateBiometric(); },
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                  label: const Text("Google"),
                ),
                ElevatedButton.icon(
                  onPressed: () { auth.signInWithMicrosoft(); _authenticateBiometric(); },
                  icon: const Icon(Icons.window, color: Colors.white),
                  label: const Text("Microsoft"),
                ),
                ElevatedButton.icon(
                  onPressed: () { auth.signInWithApple(); _authenticateBiometric(); },
                  icon: const Icon(Icons.apple, color: Colors.white),
                  label: const Text("Apple"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
