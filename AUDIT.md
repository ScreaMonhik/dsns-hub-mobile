# Аудит dsns-hub-mobile

**Дата:** 13 сентября 2026  
**Репозиторий:** `dsns-hub-mobile`  
**Пакет:** `dsns_hub` **0.1.0+1** · Dart `^3.12.2` · локаль `uk_UA`  
**Режим:** read-only на момент аудита

Смежные сервисы: `dsns-hub-backend`, `dsns-hub-admin`.

---

## Самари

Flutter-клиент сотрудника: новости (TipTap), PDF документов/проектов, опросы, Socket.IO чаты, профиль, inbox экстренных алертов, offline-скачивание PDF, maintenance, feature flags (Remote Config). Архитектура **feature-first** + `core/`: Riverpod, go_router (5 вкладок), Dio с refresh, Drift (кэш списков + offline PDF), Firebase (core, messaging, Crashlytics, remote config), Liquid Glass tab bar.

Security-слой самый сильный из трёх клиентов: токены только в secure storage, пароль не пишется на диск, app lock (cold start + 2 мин фон), SHA-256 pinning на Dio, freeRASP, sanitized logs, safe URL/file, `allowBackup=false`. Это всё ещё **не store-ready**: debug signing, `com.example.*`, deeplink объявлен но не обработан, pinning не на Socket.IO, тестов 7 файлов.

Зрелость: alpha/beta с сильным security-слоем; не готов к магазину.

---

## Метрики

| Метрика | Значение |
|---|---|
| Features | 10 |
| Экраны | 22 |
| Repositories | 9 |
| Ручные Dart-файлы | ~100 |
| Тесты | 7 |
| Integration tests | 0 |
| CI | release APK/iOS symbols |
| Fastlane | нет |
| ARB / l10n | нет (хардкод українською) |

---

## Карта фич

| Feature | Экраны |
|---|---|
| auth | login, register |
| news | лента, деталь (TipTap, YouTube, video, votes, comments) |
| documents | список, PDF, offline |
| projects | список, деталь, PDF, offline |
| polls | список + голос |
| chats | список, переписка, info |
| profile | профиль, settings, notification prefs, alerts inbox/detail |
| home | shell + Liquid Glass tabs |
| maintenance | полноэкранный техрежим |
| offline | скачанные PDF |

Роутер: `/login`, `/register`, `/news`, `/documents`, `/projects`, `/polls`, `/chats`, `/profile/*`, `/maintenance`. Редирект учитывает auth, maintenance и feature flags.

---

## Сессия

1. Логин пишет `jwt_token` + `refresh_token` в Keychain / EncryptedSharedPreferences.
2. На старте: живой access → сессия; **протухший access удаляется, refresh остаётся для Face ID** — не silent refresh.  
   `lib/features/auth/providers/auth_provider.dart:97-110`  
   README (`Прострочений access на старті оновлюється`) **расходится с кодом**.
3. 401 на REST → один refresh через отдельный `refreshDio`.
4. App lock overlay; выход чистит ключи и зовёт `/auth/logout`.
5. Ключ `biometric_password` только удаляется, никогда не пишется.

---

## Находки

### HIGH

1. **Release Android подписан debug-ключом.**  
   `android/app/build.gradle.kts:32-36`

2. **`applicationId` / bundle = `com.example.*`.**  
   `android/app/build.gradle.kts:21-22`, `lib/core/config/app_config.dart:15-28`

3. **Deeplink `dsns://` в манифесте/plist и в share, в Dart не обрабатывается.**  
   Share: `dsns://hub.dsns.gov.ua/news/:id`. Universal Links нет.

4. **Socket.IO без certificate pinning.** Dio защищён, чат — нет.  
   `lib/features/chats/data/services/chat_socket_service.dart`

5. **Firebase обязателен на старте.** Нет `firebase_options` / plist / json в репо — без локальной настройки `main()` падает.  
   `lib/main.dart:34-35`

6. **RASP с placeholder hash/teamId**, если CI secrets пустые.  
   `lib/core/security/device_integrity.dart:61-75`

### MEDIUM

7. Покрытие тестами <5%: pinning, maintenance JSON, push routes, TipTap text, tab bar. Нет auth/Dio/router/PDF/offline.
8. iOS job в CI без `analyze`/`test` и без TestFlight.  
   `.github/workflows/release.yml`
9. Drift API cache без TTL — офлайн может бесконечно показывать устаревшее.
10. Дубли PDF-экранов документов и проектов.
11. Нет `Semantics` — VoiceOver/TalkBack почти слепые на табах.
12. Нет защиты от скриншотов на чатах/PDF/алертах.
13. Push `router.go` не сохраняет pending deep link, если пользователь не залогинен.
14. `flutter_html` в `pubspec.yaml` не используется.

### LOW

15. Папка `features/news/presentations/` vs `presentation/` у остальных.
16. `register_screen.dart` ~543 LOC, `news_detail_screen.dart` ~489 LOC.
17. i18n только хардкод `uk`.
18. Polls/chats/alerts без offline cache.
19. FCM background handler только инициализирует Firebase.
20. `analysis_options.yaml` — базовый `flutter_lints`.
21. `dioProvider` ↔ `authStateProvider` циклически связаны; спасает отдельный `refreshDio`, но шов хрупкий.

---

## Что хорошо

Единый `AppConfig.apiBaseUrl`; QueuedInterceptor + отдельный refresh Dio; isolate JSON; safe URL (только http/https, YouTube whitelist); sanitization имён PDF; offline banner + invalidate списков; maintenance persist + poll; feature flags; Crashlytics только в release; obfuscate + split-debug-info в CI; Liquid Glass tab bar с тестом.

---

## Рекомендации

1. Свой applicationId + release keystore / CI signing.
2. Обработать `dsns://` (и лучше App Links) в go_router; очередь pending route после логина.
3. Либо silent refresh на cold start, либо поправить README.
4. Pin / ограничить Socket.IO так же, как Dio.
5. Тесты: auth bootstrap, 401 refresh, router redirects, repositories.
6. Общий PDF viewer; Semantics на табах; TTL кэша.
7. PR CI: `analyze` + `test` на каждый push (включая iOS job).

---

Документ описывает состояние дерева **на 13 сентября 2026**.
