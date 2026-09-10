import 'package:intl/intl.dart';

/// Shared [DateFormat] instances. Constructing a formatter on every list row is expensive.
class AppDateFormats {
  static final DateFormat time = DateFormat('HH:mm');
  static final DateFormat dayMonthYear = DateFormat('dd MMM yyyy');
  static final DateFormat dayMonthYearTime = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat dayMonthTime = DateFormat('dd MMM HH:mm');
  static final DateFormat longDayMonthYearTime = DateFormat('dd MMMM yyyy, HH:mm');
  static final DateFormat dayMonthHour = DateFormat('dd.MM HH:mm');
  static final DateFormat dottedDate = DateFormat('dd.MM.yyyy');
  static final DateFormat dottedDateTime = DateFormat('dd.MM.yyyy HH:mm');
}
