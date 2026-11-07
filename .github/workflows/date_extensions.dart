import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  static const List<String> marathiMonths = [
    'जानेवारी',
    'फेब्रुवारी',
    'मार्च',
    'एप्रिल',
    'मे',
    'जून',
    'जुलै',
    'ऑगस्ट',
    'सप्टेंबर',
    'ऑक्टोबर',
    'नोव्हेंबर',
    'डिसेंबर'
  ];

  static const List<String> hindiMonths = [
    'जनवरी',
    'फ़रवरी',
    'मार्च',
    'अप्रैल',
    'मई',
    'जून',
    'जुलाई',
    'अगस्त',
    'सितंबर',
    'अक्टूबर',
    'नवंबर',
    'दिसंबर'
  ];

  String toFormattedDate() {
    return DateFormat('dd-MM-yyyy').format(this);
  }

  String toFormattedDateTime() {
    return DateFormat('dd-MM-yyyy hh:mm a').format(this);
  }

  String toMarathiMonthYear() {
    return '${marathiMonths[month - 1]} $year';
  }

  String toLocalizedMonthYear(String languageCode) {
    if (languageCode == 'mr') {
      return '${marathiMonths[month - 1]} $year';
    } else if (languageCode == 'hi') {
      return '${hindiMonths[month - 1]} $year';
    }
    return DateFormat('MMMM yyyy').format(this);
  }
}
