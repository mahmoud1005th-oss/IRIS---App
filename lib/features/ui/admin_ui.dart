import 'package:flutter/material.dart';
import 'menu_v5.dart' show AdminV5;

// لوحة المايسترو: بتفتح لحساب الأدمن بس (AuthService.isAdmin).
class AdminUI extends StatelessWidget {
  const AdminUI({super.key});

  @override
  Widget build(BuildContext context) => const AdminV5();
}
