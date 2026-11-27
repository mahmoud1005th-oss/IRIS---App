# IRIS: where each DeepSeek piece plugs in

Every piece is a small interface in `lib/core/services/` with a placeholder that does nothing.
While an endpoint constant is empty the app behaves exactly as today (test replies, phone voice).

| Piece | File | What to set / replace | Used from |
|---|---|---|---|
| Chat / AI answers | `chat_service.dart` | `kChatEndpoint` (POST JSON, replies `{"text":...}`), or write a new `ChatService` | `v34_home.dart` `_deliver()` |
| Speech to text | `stt_service.dart` | `kSttEndpoint` (multipart `audio`, `lang`; replies `{"text":...}`) | `v34_home.dart` `_stt` (voice CC) |
| Text to speech | `tts_service.dart` | `kTtsEndpoint` (replies audio bytes). Not yet called: today the speaker icon uses the phone voice (`flutter_tts`) in `_initTts` / speak in `v34_home.dart`. Wiring step: if `makeTtsService().connected`, play the returned file with audioplayers, else phone voice | `v34_home.dart` |
| Auth + avatar | `auth_service.dart` | Put real `supabaseUrl` and `supabaseAnonKey`. Avatar shows the first letter of the name (`displayName`) or email | `menu_v5.dart` `AccountAvatar`, `main.dart`, `login_page.dart` |
| Usage cap | `usage_service.dart` | Replace `PlaceholderUsageService` with server numbers | `menu_v5.dart` `UsageCap` (still shows fixed 3 of 7, not yet reading the service) |

Real today: mic recording and playback, chat saved on the phone (`iris_thread_v1`), phone TTS, fingerprint lock.
Admin account: `AuthService.adminEmail`. The check is client side only, enforce it on the server too.
Model names shown to users: Auto, Flash Lite, Flash, Pro Lite (sent as `mode`).
