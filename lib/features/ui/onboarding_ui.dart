import 'package:flutter/material.dart';
import 'hologram_ui.dart';

// شاشة الترحيب بعد تسجيل الدخول: اختيار اللغة والجنس (لتخصيص صوت آيرس)
// أزرار تسجيل الدخول اتنقلت لشاشة Login الجديدة (V3)
class OnboardingUI extends StatefulWidget {
  const OnboardingUI({super.key});
  @override
  State<OnboardingUI> createState() => _OnboardingUIState();
}

class _OnboardingUIState extends State<OnboardingUI> {
  String? gender;
  String language = "ar";

  void _goToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => HologramUI(gender: gender, language: language)),
    );
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
              if (gender != null)
                ElevatedButton.icon(
                  onPressed: _goToNextScreen,
                  icon: const Icon(Icons.rocket_launch, color: Colors.black),
                  label: const Text("ابدأ", style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
