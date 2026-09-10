class PasswordRules {
  static final RegExp regex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  static const String message =
      'Пароль занадто простий. Мінімум 8 символів: 1 велика, 1 мала літера, 1 цифра та спецсимвол.';

  static bool isValid(String password) => regex.hasMatch(password);
}
