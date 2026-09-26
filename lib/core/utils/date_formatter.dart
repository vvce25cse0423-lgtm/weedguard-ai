import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _dbDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime dt) => _date.format(dt);
  static String formatDateTime(DateTime dt) => _dateTime.format(dt);
  static String formatTime(DateTime dt) => _time.format(dt);
  static String formatMonthYear(DateTime dt) => _monthYear.format(dt);
  static String formatDbDate(DateTime dt) => _dbDate.format(dt);
}
