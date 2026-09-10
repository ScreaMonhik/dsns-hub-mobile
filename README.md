# DSNS Hub Mobile

Мобільний клієнт внутрішнього порталу **ДСНС України** (Flutter). Додаток дає співробітникам доступ до новин, документів, проєктів, опитувань і службових чатів з єдиною авторизацією, захищеним сховищем токенів і блокуванням сесії.

| | |
| --- | --- |
| Пакет | `dsns_hub` |
| Версія | `0.1.0+1` |
| SDK | Dart `^3.12.2` |
| Стан | `publish_to: none` (внутрішній продукт) |
| Локаль UI | українська (`uk_UA`) |
| Android applicationId | `com.example.dsns_hub` |
| Deep link | `dsns://` |

---

## Можливості

### Авторизація та профіль
- Вхід за email / паролем (`@dsns.gov.ua` на реєстрації).
- Реєстрація з вибором області та підрозділу (пошук підрозділів з debounce).
- Пара JWT: access + refresh. Прострочений access на старті оновлюється через `/auth/refresh`.
- Вихід інвалідує сесію на сервері й чистить локальні ключі.
- Профіль: ПІБ, email, роль, аватар (камера / галерея), зміна пароля.
- Тема: системна / світла / темна (зберігається в secure storage).
- Очищення тимчасового кешу (PDF тощо).

### Новини
- Стрічка з пагінацією, пошуком і фільтром за категоріями.
- Деталі з рендером того ж TipTap JSON, що зберігає адмінка: H2/H3, абзаци, списки, цитати, зображення, завантажене відео, YouTube, code block, горизонтальна лінія, marks (bold / italic / underline / strike / code / link).
- Дата на картці й у деталях — `publishedAt`, інакше `createdAt` (як прев’ю в адмінці).
- YouTube відкривається зовні як watch-URL; дозволені лише youtube.com / youtu.be / youtube-nocookie.
- Лайки / дизлайки, коментарі.
- Шеринг через `dsns://hub.dsns.gov.ua/news/:id`.
- Після голосу оновлюється лише картка, а не вся стрічка.

### Документи та проєкти
- Списки з пошуком і пагінацією.
- Перегляд PDF у додатку (Syncfusion): пошук по тексту, друк, системний share.
- У проєктах — голосування, коментарі, окремий PDF-екран.

### Опитування
- Фільтри: усі / активні / не пройдені / пройдені / завершені.
- Голос по варіанту, дедлайн і статус «завершено» з урахуванням локального часу.

### Чати
- Список груп, непрочитані, прев’ю останнього повідомлення.
- Realtime через Socket.IO (`/chat`): нові / змінені / видалені повідомлення, read receipts.
- Пагінація історії, відмітка прочитаного пачкою.
- Інформація про групу та аватар чату.

### Безпека та надійність
- Токени лише в `flutter_secure_storage` (EncryptedSharedPreferences / Keychain, без iCloud sync).
- Пароль **не** зберігається на пристрої.
- App lock: після холодного старту та після 2 хв у фоні — біометрія або PIN пристрою.
- HTTP-логи тільки в debug і без заголовків / тіл (щоб не світити Bearer і PII).
- Android: `allowBackup=false`, cleartext лише для `10.0.2.2` / `localhost` / `127.0.0.1`.
- Зовнішні посилання з TipTap відкриваються тільки як `http` / `https`.
- Імена завантажених PDF санітизуються (без path traversal).
- Банер офлайну; при появі мережі списки інвалідуються й підтягуються знову.
- Push: Firebase Cloud Messaging + локальний канал `emergency_alerts`.

---

## Стек

| Шар | Технології |
| --- | --- |
| UI | Flutter, Material 3, `go_router`, `animations`, `flutter_animate`, `shimmer` |
| Стан | Riverpod (`Provider`, `StateNotifier`, `AsyncNotifier`, `FutureProvider`) |
| Мережа | Dio + `QueuedInterceptorsWrapper` (Bearer, refresh, 429) |
| Realtime | `socket_io_client` (websocket) |
| Моделі | Freezed + `json_serializable` |
| Сховище | `flutter_secure_storage` |
| Auth lock | `local_auth` |
| Файли | `path_provider`, Syncfusion PDF, `printing`, `share_plus` |
| Сповіщення | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Медіа в новинах | `video_player` (завантажене відео з JWT), `url_launcher` (YouTube / посилання) |
| Інше | `connectivity_plus`, `image_picker`, `package_info_plus` |

Архітектура екранів — feature-first:

```
lib/
  main.dart
  core/                         # мережа, роутер, тема, безпека, віджети
    config/app_config.dart      # API_BASE_URL
    network/dio_provider.dart
    router/app_router.dart
    security/                   # JWT, біометрія, app lock, пароль
    storage/
    services/                   # FCM
    presentation/
    utils/                      # дати, safe URL / file, media URL
  features/
    auth/
    news/
    documents/
    projects/
    polls/
    chats/
    profile/
    home/                       # bottom shell
```

Кожна фіча, де доречно: `data/models`, `data/repositories`, `presentation/screens|widgets|providers`.

---

## Вимоги

- [Flutter](https://docs.flutter.dev/get-started/install) зі SDK Dart 3.12+
- Xcode (iOS) / Android Studio з емулятором API, сумісним із `flutter.minSdkVersion`
- Запущений бекенд DSNS Hub (за замовчуванням порт `3000`)
- Firebase-проєкт і файли конфігурації (див. нижче)

Перевірка:

```bash
flutter doctor
flutter pub get
```

---

## Швидкий старт

### 1. Бекенд

Емулятор Android бачить хост-машину як `10.0.2.2`. Це дефолтний `API_BASE_URL`.

| Середовище | Типовий URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:3000` |
| iOS Simulator | `http://127.0.0.1:3000` |
| Фізичний пристрій | `http://<LAN-IP>:3000` (лише debug; у release HTTP на LAN заблокований ATS / network security) |
| Прод | `https://<ваш-api>` через `--dart-define` |

iOS Simulator **не** резолвить `10.0.2.2` — обов’язково перевизначте URL.

### 2. Firebase

У репозиторії немає закомічених `google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart`. Додайте їх локально (або через CI secrets):

1. Створіть Android / iOS apps у Firebase Console.
2. Увімкніть Cloud Messaging.
3. Покладіть `google-services.json` у `android/app/`.
4. Покладіть `GoogleService-Info.plist` у `ios/Runner/`.
5. За потреби згенеруйте `lib/firebase_options.dart` через FlutterFire CLI.

Без цього `Firebase.initializeApp()` у `main()` впаде на старті.

### 3. Запуск

```bash
cd dsns-hub-mobile
flutter pub get

# Android emulator (дефолтний URL вже підходить)
flutter run

# iOS Simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000

# Прод-подібний білд
flutter run --release --dart-define=API_BASE_URL=https://api.example.gov.ua
```

Після зміни моделей:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Конфігурація

Єдине джерело URL — `lib/core/config/app_config.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);
```

Те саме значення використовують Dio, Socket.IO та захищені зображення (`AuthNetworkImage`).

Приклади:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
flutter build apk --dart-define=API_BASE_URL=https://hub-api.dsns.gov.ua
flutter build ipa --dart-define=API_BASE_URL=https://hub-api.dsns.gov.ua
```

---

## Навігація

`GoRouter` з `StatefulShellRoute` (п’ять вкладок). Поки йде перевірка токена, неавторизовані маршрути редіректять на `/login`.

| Маршрут | Екран |
| --- | --- |
| `/login` | Вхід |
| `/register` | Реєстрація |
| `/profile` | Профіль і налаштування |
| `/news` | Стрічка новин |
| `/news/:id` | Новина (`?comments=true` — скрол до коментарів) |
| `/documents` | Документи |
| `/documents/view` | PDF (`extra: DocumentModel`) |
| `/projects` | Проєкти |
| `/projects/:id` | Деталі проєкту |
| `/projects/:id/pdf` | PDF проєкту (`extra: ProjectModel`) |
| `/polls` | Опитування |
| `/polls/:id` | Голосування |
| `/chats` | Список чатів |
| `/chats/:id` | Переписка |
| `/chats/:id/info` | Учасники / аватар групи |

Кастомна схема: `dsns://hub.dsns.gov.ua/news/<id>` (Android `intent-filter` + iOS `CFBundleURLTypes`). Універсальні App Links / `https` поки не підключені.

---

## API, з яким говорить клієнт

Базовий REST (Bearer після логіну):

| Метод | Шлях | Призначення |
| --- | --- | --- |
| POST | `/auth/login` | `accessToken`, `refreshToken` |
| POST | `/auth/register` | нова обліковка |
| POST | `/auth/refresh` | ротація токенів |
| POST | `/auth/logout` | інвалідація сесії |
| PATCH | `/auth/session/fcm-token` | реєстрація FCM |
| GET | `/departments/public/regions` | області |
| GET | `/departments/public/search` | підрозділи |
| GET | `/users/me` | профіль |
| PATCH | `/users/me/avatar` | аватар (`multipart`) |
| PATCH | `/users/me/password` | зміна пароля |
| GET | `/news`, `/news/:id`, `/news/categories` | новини |
| POST | `/news/:id/vote`, `/news/:id/comments` | реакції |
| GET | `/documents`, `/documents/:id` | документи + download fileUrl |
| GET | `/projects`, `/projects/:id` | проєкти |
| POST | `/projects/:id/vote`, `/projects/:id/comments` | реакції |
| GET | `/polls`, `/polls/:id` | опитування |
| POST | `/polls/:id/vote` | `{ optionId }` |
| GET | `/chat/groups`, `/chat/groups/:id/messages`, `/.../members` | чати |
| POST | `/chat/groups/:id/avatar` | аватар групи |

Socket.IO namespace: `{API_BASE_URL}/chat`, auth `{ token }`.

Події клієнт → сервер: `joinRoom`, `sendMessage`, `editMessage`, `deleteMessage`, `markAsRead`.

Події сервер → клієнт: `newMessage`, `messageUpdated`, `messageDeleted`, `messagesRead`, `exception`.

Dio: connect 15 с, receive/send 30 с; завантаження PDF — receive до 2 хв. На `401` (крім login/refresh) — одна спроба refresh, далі logout. На `429` — повідомлення про ліміт.

---

## Сесія та блокування

1. Логін пише `jwt_token` + `refresh_token` у secure storage.
2. На старті: валідний access → сесія; інакше refresh; невдача → чистка ключів і `/login`.
3. Access додається в кожен REST-запит і в заголовки `Image.network` для захищених файлів.
4. Після паузи ≥ 2 хв (або cold start з живою сесією) показується `AppLockOverlay`.
5. Розблокування — біометрія або код пристрою (`biometricOnly: false`). Якщо не виходить — «Вийти з акаунта».

Правила пароля (реєстрація та зміна): мінімум 8 символів, велика + мала літера, цифра, спецсимвол з набору `@$!%*?&`.

---

## Сповіщення

- Background handler: `_firebaseMessagingBackgroundHandler`.
- Android-канал: `emergency_alerts` («Emergency Alerts», high importance).
- Foreground: локальне повідомлення, якщо є `notification` + Android-пейлоад.
- Після логіну клієнт просить дозвіл і шле FCM-токен на `/auth/session/fcm-token`, далі слухає `onTokenRefresh`.

Потрібен runtime-дозвіл `POST_NOTIFICATIONS` (Android 13+).

---

## Збірка

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # *.freezed.dart / *.g.dart у .gitignore
flutter analyze
flutter test
flutter build apk --dart-define=API_BASE_URL=https://...
flutter build appbundle --dart-define=API_BASE_URL=https://...
flutter build ipa --dart-define=API_BASE_URL=https://...
```

Release зараз підписаний **debug-ключами** (`android/app/build.gradle.kts`) — для магазину потрібен власний keystore і не `com.example.*` applicationId.

---

## Перед релізом

- [ ] Власний `applicationId` / bundle id, іконки, display name
- [ ] Release signing (не debug)
- [ ] `--dart-define=API_BASE_URL=https://...` на всіх CI-джобах
- [ ] Firebase prod apps + валідні plist/json
- [ ] Перевірити Face ID / відбиток і lock після 2 хв у фоні
- [ ] PDF великих файлів, офлайн-банер, refresh токена після простою
- [ ] HTTPS App Links замість (або разом із) `dsns://`

---

## Корисні шляхи

| Файл | Роль |
| --- | --- |
| `lib/main.dart` | Firebase, локаль `uk`, lifecycle → app lock |
| `lib/core/network/dio_provider.dart` | HTTP-клієнт і refresh |
| `lib/core/config/app_config.dart` | базовий URL |
| `lib/features/auth/providers/auth_provider.dart` | сесія |
| `lib/features/chats/data/services/chat_socket_service.dart` | realtime |
| `android/app/src/main/res/xml/network_security_config.xml` | TLS / cleartext |
| `android/app/src/main/AndroidManifest.xml` | INTERNET, FCM, `dsns://` |

---

## Ліцензія

Внутрішній проєкт. `publish_to: 'none'` — пакет не публікується на pub.dev.
