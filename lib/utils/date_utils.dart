import 'package:intl/intl.dart';

String convertExcelDate(String? excelDate) {
  if (excelDate == null || excelDate.isEmpty) return "Unknown Date";

  try {
    print("✅ Raw Excel Date: $excelDate");

    double serial = double.tryParse(excelDate) ?? 0;
    int days = serial.floor(); // Ignore decimal part
    DateTime date = DateTime(1899, 12, 30).add(Duration(days: days));

    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    print("✅ Converted Date: $formattedDate");
    return formattedDate;
  } catch (e) {
    print("❌ Error converting Excel date: $e");
    return "Invalid Date";
  }
}
