import 'dart:math';
import 'package:flutter/material.dart';

class HologramUI extends StatefulWidget {
  const HologramUI({super.key});

  @override
  State<HologramUI> createState() => _HologramUIState();
}

class _HologramUIState extends State<HologramUI> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
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
