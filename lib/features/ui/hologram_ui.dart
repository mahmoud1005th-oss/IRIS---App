import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HologramUI extends StatefulWidget {
  final String? gender;
  final String? language;
  const HologramUI({super.key, this.gender, this.language});

  @override
  State<HologramUI> createState() => _HologramUIState();
}

class _HologramUIState extends State<HologramUI> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // تخصيص صوت آيرس
  final FlutterTts _flutterTts = FlutterTts();
  String selectedVoice = "male"; // أو female بناءً على اللي اختاره في الـ Onboarding

  // الـ 5 أصوات المتاحة
  static const Map<String, String> voiceLabels = {
    "male": "رجل",
    "female": "ست",
    "child": "طفل",
    "young": "شاب",
    "old": "عجوز",
  };
  static const Map<String, double> _voicePitch = {
    "male": 1.0,
    "female": 1.3,
    "child": 1.8,
    "young": 1.2,
    "old": 0.7,
  };
  static const Map<String, double> _voiceRate = {
    "male": 0.5,
    "female": 0.5,
    "child": 0.55,
    "young": 0.5,
    "old": 0.4,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    // الصوت الافتراضي بناءً على جنس المستخدم اللي اختاره في الـ Onboarding
    selectedVoice = (widget.gender == "female") ? "female" : "male";
    _initVoice();
  }

  String get _locale => widget.language == "en" ? "en-US" : "ar-EG";

  Future<void> _initVoice() async {
    try {
      await _flutterTts.setLanguage(_locale);
      await _changeVoice(selectedVoice);
    } catch (_) {}
  }

  Future<void> _changeVoice(String voiceType) async {
    setState(() => selectedVoice = voiceType);
    try {
      // كود تغيير الصوت من الـ 5 أصوات المتاحة
      await _flutterTts.setVoice({"name": voiceType, "locale": _locale});
      await _flutterTts.setPitch(_voicePitch[voiceType] ?? 1.0);
      await _flutterTts.setSpeechRate(_voiceRate[voiceType] ?? 0.5);
    } catch (_) {}
  }

  void _showVoicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("اختر صوت آيرس", style: TextStyle(color: Colors.cyanAccent, fontSize: 18)),
              ),
              ...voiceLabels.entries.map(
                (e) => ListTile(
                  leading: Icon(
                    selectedVoice == e.key ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: Colors.cyanAccent,
                  ),
                  title: Text(e.value, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    _changeVoice(e.key);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية السوداء مع تأثير الهولوغرام
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: HologramPainter(_controller.value),
                );
              },
            ),
          ),
          // الشعار
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.5 + (_controller.value * 0.5)),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
                  );
                },
              ),
            ),
          ),
          // زرار اختيار الصوت
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: IconButton(
                onPressed: _showVoicePicker,
                icon: const Icon(Icons.record_voice_over, color: Colors.cyanAccent, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HologramPainter extends CustomPainter {
  final double animationValue;
  HologramPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // رسم دوائر متوسعة (محاكاة النبض الهولوغرامي)
    for (int i = 0; i < 3; i++) {
      double radius = (size.width * 0.3) + (i * 30) + (animationValue * 50);
      canvas.drawCircle(center, radius, paint);
    }

    // رسم خطوط تكتيكية عشوائية تشبه الرادار
    final random = Random(42); // رقم ثابت عشان الشكل ميتغيرش عشوائياً
    for (int i = 0; i < 10; i++) {
      double angle = random.nextDouble() * 2 * pi;
      double startRadius = size.width * 0.3;
      double endRadius = startRadius + 40 + (animationValue * 20);

      Offset start = Offset(center.dx + startRadius * cos(angle), center.dy + startRadius * sin(angle));
      Offset end = Offset(center.dx + endRadius * cos(angle), center.dy + endRadius * sin(angle));

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
