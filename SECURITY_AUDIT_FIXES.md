# dsns-hub-mobile — що зроблено

Гілка: `feat/store-identity-pinning-and-forced-password`  
Дата: 13 вересня 2026  
Контекст: правки за [AUDIT.md](./AUDIT.md) (пункти P1, P5, P8) і спільний контур `forcePasswordChange` з backend.

## Навіщо

Релізний APK підписувався debug-ключем, `applicationId` був `com.example.dsns_hub`, pinning працював лише на Dio, а самореєстрація одразу логінила користувача. Для магазину й внутрішнього пілота це блокери.

## Ідентичність релізу

- Android `applicationId` / `namespace`: `ua.gov.dsns.hub`. `MainActivity` переїхав у пакет `ua.gov.dsns.hub`.
- iOS bundle id за замовчуванням теж `ua.gov.dsns.hub`.
- Release signing читає `android/key.properties`. Без нього Gradle падає, якщо не передати `-PallowDebugRelease=true` або `DSNS_ALLOW_DEBUG_RELEASE=true` (лише локально / CI artifact).
- CI release workflow виставляє `ANDROID_PACKAGE_NAME=ua.gov.dsns.hub` і дозволяє debug-підпис лише для артефакта пайплайна.

`key.properties` і keystore у git не потрапляють.

## Pinning і deep links

- `installPinnedHttpOverrides()` у `main()`: будь-який `HttpClient` (не лише Dio) перевіряє SHA-256 сертифіката в release.
- Deep link Android обмежено `dsns://hub.dsns.gov.ua`, увімкнено Flutter deep linking на Android і iOS.

## Реєстрація та пароль

- Після реєстрації немає автологіну. Користувач бачить, що заявка чекає активації адміністратором, і повертається на логін.
- Логін читає `user.forcePasswordChange`. Поки прапорець стоїть:
  - роутер пускає лише `/profile/settings`;
  - автоматично відкривається зміна пароля;
  - FCM-токен не синхронізується;
  - `403 FORCE_PASSWORD_CHANGE` з API знову вмикає прапорець.

## Тести та залежності

- Тести: JWT utils, password rules, pinning (у т.ч. HttpOverrides).
- Dependabot: щотижневі pub і GitHub Actions.

## Як перевірити

```bash
flutter test
```

Локальний release без keystore:

```bash
flutter build apk --release --dart-define=DSNS_ALLOW_DEBUG_RELEASE=true
```

Прод-реліз — покласти `android/key.properties` і зібрати без `allowDebugRelease`.
