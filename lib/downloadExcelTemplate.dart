// import 'dart:typed_data';
// import 'package:excel/excel.dart';
// import 'package:file_saver/file_saver.dart';

// void downloadExcelTemplateWeb() {
//   var excel = Excel.createExcel();
//   Sheet sheetObject = excel['Sheet1'];

//   // الصف الأول: أسماء الأعمدة
//   sheetObject.appendRow([
//     'farm_id',
//     'process_id',
//     'items_id',
//     'date_from (yyyy-mm-dd)',
//     'qty'
//   ]);

//   // تحويل الملف إلى بايت
//   final fileBytes = excel.encode();

//   // تحميل الملف للويب
//   if (fileBytes != null) {
//     FileSaver.instance.saveFile(
//       name: "excel_template",
//       bytes: Uint8List.fromList(fileBytes),
//       ext: "xlsx",
//       mimeType: MimeType.custom,
//       customMimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
//     );
//   }
// }
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

void downloadExcelTemplateWeb() {
  final excel = Excel.createExcel();
  final Sheet sheetObject = excel['Sheet1'];

  // قائمة بأسماء الأعمدة
  final List<String> headerTitles = [
    'farm_id',
    'process_id',
    'items_id',
    'date_from (yyyy-mm-dd)',
    'qty'
  ];

  // ✅ **التعديل**: appendRow الآن تتطلب قائمة من CellValue
  // لذا نقوم بتحويل كل عنوان نصي إلى TextCellValue
  sheetObject.appendRow(
    headerTitles.map((title) => TextCellValue(title)).toList()
  );

  // ✅ **التعديل**: نستخدم excel.save() بدلاً من excel.encode()
  final fileBytes = excel.save();

  // تحميل الملف للويب
  if (fileBytes != null) {
    FileSaver.instance.saveFile(
      name: "excel_template",
      bytes: Uint8List.fromList(fileBytes),
      ext: "xlsx",
      mimeType: MimeType.microsoftExcel,
    );
  }
}