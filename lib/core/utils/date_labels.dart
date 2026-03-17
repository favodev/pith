class DateLabels {
  const DateLabels._();

  static const List<String> _months = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  static String monthAbbreviation(int month) {
    if (month < 1 || month > 12) {
      return 'MES';
    }

    return _months[month - 1];
  }

  static String monthDay(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }

    return '${monthAbbreviation(date.month)} ${date.day}';
  }

  static String monthDayYear(DateTime date) {
    return '${monthAbbreviation(date.month)} ${date.day}, ${date.year}';
  }
}
