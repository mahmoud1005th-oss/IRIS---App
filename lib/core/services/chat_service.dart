import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ذكاء آيرس (الرد على الرسائل). نقطة التوصيل للـ Cloudflare Worker.
// لما محمود ينشر الـ Worker: حط رابطه في kChatEndpoint وكلمة السر المشتركة في kAppToken.
// السيرفر يستقبل POST JSON:
// {"messages":[{"role":"user|assistant","content":"..."}], "mode":"auto|flashLite|flash|proLite", "lang":"ar"}
// ويرد JSON: {"text":"..."}
const String kChatEndpoint = 'https://iris-brain.mahmoud1005th.workers.dev'; // فاضي = الذكاء مش متوصل، والتطبيق بيعرض ردود تجريبية
const String kAppToken = 'iris-63e423f565dc5cae6e0d'; // نفس كلمة APP_TOKEN المتخزنة في الـ Worker؛ فاضي = من غير

class ChatTurn {
  final String role; // user | assistant
  final String text;
  const ChatTurn(this.role, this.text);
}

class ChatResult {
  final String? text;
  final String? error;
  const ChatResult.ok(String t)
      : text = t,
        error = null;
  const ChatResult.fail(String e)
      : text = null,
        error = e;
  bool get ok => text != null;
}

abstract class ChatService {
  bool get connected;
  Future<ChatResult> reply(List<ChatTurn> history,
      {String mode = 'auto', String lang = 'ar'});
}

class PlaceholderChatService implements ChatService {
  const PlaceholderChatService();
  @override
  bool get connected => false;
  @override
  Future<ChatResult> reply(List<ChatTurn> history,
          {String mode = 'auto', String lang = 'ar'}) async =>
      const ChatResult.fail('not_connected');
}

class HttpChatService implements ChatService {
  final String endpoint;
  const HttpChatService(this.endpoint);
  @override
  bool get connected => true;
  @override
  Future<ChatResult> reply(List<ChatTurn> history,
      {String mode = 'auto', String lang = 'ar'}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (kAppToken.isNotEmpty) headers['X-IRIS-Token'] = kAppToken;
      final res = await http
          .post(Uri.parse(endpoint),
              headers: headers,
              body: jsonEncode({
                'messages': [
                  for (final t in history) {'role': t.role, 'content': t.text}
                ],
                'mode': mode,
                'lang': lang,
              }))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) return ChatResult.fail('http_${res.statusCode}');
      final t = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['text'];
      if (t is! String || t.trim().isEmpty) return const ChatResult.fail('empty');
      return ChatResult.ok(t.trim());
    } on SocketException {
      return const ChatResult.fail('offline');
    } catch (_) {
      return const ChatResult.fail('error');
    }
  }
}

ChatService makeChatService() => kChatEndpoint.isEmpty
    ? const PlaceholderChatService()
    : const HttpChatService(kChatEndpoint);
