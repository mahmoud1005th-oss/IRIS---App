import 'package:flutter/material.dart';

class AdminUI extends StatelessWidget {
  const AdminUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("لوحة المايسترو - Admin Panel"), backgroundColor: Colors.cyanAccent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("أهلاً بك يا مايسترو محمود 👑", style: TextStyle(color: Colors.cyanAccent, fontSize: 22)),
          const Divider(),
          ListTile(leading: const Icon(Icons.key, color: Colors.white), title: const Text("إدارة مفاتيح API", style: TextStyle(color: Colors.white)), subtitle: const Text("تغيير OpenRouter / Replicate Keys", style: TextStyle(color: Colors.grey))),
          ListTile(leading: const Icon(Icons.people, color: Colors.white), title: const Text("إدارة المستخدمين", style: TextStyle(color: Colors.white)), subtitle: const Text("ترقية مستخدم لـ Pro / حظر مستخدم", style: TextStyle(color: Colors.grey))),
          ListTile(leading: const Icon(Icons.attach_money, color: Colors.white), title: const Text("إدارة التسعير", style: TextStyle(color: Colors.white)), subtitle: const Text("تعديل أسعار الباقات", style: TextStyle(color: Colors.grey))),
          ListTile(leading: const Icon(Icons.analytics, color: Colors.white), title: const Text("الإحصائيات", style: TextStyle(color: Colors.white)), subtitle: const Text("عدد الصور والفيديوهات المولدة", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
