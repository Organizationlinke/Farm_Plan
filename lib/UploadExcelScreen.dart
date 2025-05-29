import 'dart:math';

import 'package:farmplanning/downloadExcelTemplate.dart';
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class UploadExcelScreen extends StatefulWidget {
  @override
  _UploadExcelScreenState createState() => _UploadExcelScreenState();
}

class _UploadExcelScreenState extends State<UploadExcelScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> uploads = [];
  // int uploadId = DateTime.now().millisecondsSinceEpoch; // رقم ثابت لكل عملية
  int uploadId = 1000; // رقم بين 1000 و9999
  String uploadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    fetchUploads();
    getNextUploadId();
  }

  Future<void> fetchUploads() async {
    final response = await supabase
        .from('upload_list')
        .select();

    final unique = {
      for (var row in response)
        row['upload_id']: row
    }.values.toList();

    setState(() {
      uploads = unique;
    });
  }
Future<void> getNextUploadId() async {
  final response = await Supabase.instance.client
      .from('data_table')
      .select('upload_id')
      .order('upload_id', ascending: false)
      .limit(1);

  if (response.isNotEmpty && response[0]['upload_id'] != null) {
    uploadId = response[0]['upload_id'] + 1;
  } else {
    uploadId = 1000; // أول قيمة عند عدم وجود أي بيانات
  }
  print('uploadId:$uploadId');
}
  Future<void> deleteUpload(int uploadId) async {
    await supabase.from('data_table').delete().eq('upload_id', uploadId);
    fetchUploads();
  }
   Future<void> AcceptUpload(int uploadId) async {
    await supabase.from('data_table').update({'Accept_upload':1}).eq('upload_id', uploadId);
    fetchUploads();
  }
  Future<void> _confirmDelete(int uploadId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('تأكيد الحذف'),
      content: Text('هل أنت متأكد أنك تريد حذف هذه العملية؟'),
      actions: [
        TextButton(child: Text('إلغاء'), onPressed: () => Navigator.of(context).pop(false)),
        ElevatedButton(child: Text('نعم، احذف'), onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );

  if (confirmed == true) {
    await deleteUpload(uploadId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحذف بنجاح')));
  }
}

Future<void> _confirmAccept(int uploadId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('تأكيد القبول'),
      content: Text('هل تريد قبول هذه البيانات؟'),
      actions: [
        TextButton(child: Text('إلغاء'), onPressed: () => Navigator.of(context).pop(false)),
        ElevatedButton(child: Text('نعم، قبول'), onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );

  if (confirmed == true) {
    await AcceptUpload(uploadId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم القبول بنجاح')));
  }
}

Future<void> uploadFromExcel() async {
 await getNextUploadId();
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true, // مهم جدًا على الويب
  );

  if (result == null || result.files.single.bytes == null) return;

  final bytes = result.files.single.bytes!;
  final excel = Excel.decodeBytes(bytes);

  final sheet = excel.tables.values.first;
  if (sheet == null) return;

for (var row in sheet.rows.skip(1)) {
  final farmId = int.tryParse(row[0]?.value.toString() ?? '');
  final processId = int.tryParse(row[1]?.value.toString() ?? '');
  final itemId = int.tryParse(row[2]?.value.toString() ?? '');
  
  // تحويل التاريخ بالتنسيق المطلوب
  String? rawDate = row[3]?.value.toString();
  DateTime? parsedDate;
  if (rawDate != null) {
    try {
      parsedDate = DateTime.parse(rawDate); // يحاول التحويل التلقائي
    } catch (e) {
      print('فشل في تحويل التاريخ: $rawDate');
    }
  }

  final formattedDate = parsedDate != null
      ? DateFormat('yyyy-MM-dd').format(parsedDate)
      : null;

  final qty = double.tryParse(row[4]?.value.toString() ?? '');

  if (farmId == null || processId == null || itemId == null || qty == null || formattedDate == null) continue;

  // التحقق من المفاتيح الأجنبية
  final farm = await supabase.from('farm').select().eq('id', farmId!);
  final process = await supabase.from('process').select().eq('id', processId!);
  final item = await supabase.from('items').select().eq('id', itemId!);

  // if (farm.isEmpty || process.isEmpty || item.isEmpty) continue;

  // الإدخال
  await supabase.from('data_table').insert({
    'farm_id': farmId,
    'process_id': processId,
    'items_id': itemId,
    'date_from': formattedDate, // التنسيق الجديد
    'date_to': formattedDate,
    'qty': qty,
    'upload_id': uploadId,
    'upload_date': uploadDate,
  });
}




  fetchUploads();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("تم رفع البيانات بنجاح")),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
           backgroundColor: colorbar,
          foregroundColor: Colorapp,
        title: Text('تحميل بيانات من Excel'),
         actions: [
    IconButton(
      icon: Icon(Icons.download),
      tooltip: 'تحميل قالب Excel',
      onPressed: () async {
         downloadExcelTemplateWeb();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحميل قالب Excel بنجاح')),
        );
      },
    ),
    IconButton(
      icon: Icon(Icons.upload_file),
      tooltip: 'تحميل من Excel',
      onPressed: uploadFromExcel,
    ),
  ],
    
      ),
      body: ListView.builder(
        itemCount: uploads.length,
        itemBuilder: (context, index) {
          final upload = uploads[index];
          return Card(
            child: ListTile(
                  title: Text('عملية رقم: ${upload['upload_id']}',style: TextStyle(color: MainFoantcolor,fontSize:18,fontFamily: 'myfont')),
                  subtitle: Text('تاريخ: ${upload['upload_date']}',style: TextStyle( color:color_under,fontFamily: 'myfont' )),
                  trailing: SizedBox(
                    width: 100, // علشان الـ Row تاخد مساحة كافية
                    child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'قبول',
                onPressed: () => _confirmAccept(upload['upload_id']),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                tooltip: 'حذف',
                onPressed: () => _confirmDelete(upload['upload_id']),
              ),
            ],
                    ),
                  ),
            ),
          );
        },
      ),

      // body: ListView.builder(
      //   itemCount: uploads.length,
      //   itemBuilder: (context, index) {
      //     final upload = uploads[index];
      //     return ListTile(
      //       title: Text('عملية رقم: ${upload['upload_id']}'),
      //       subtitle: Text('تاريخ: ${upload['upload_date']}'),
      //       trailing: Row(
      //         children: [
      //            IconButton(
      //             icon: Icon(Icons.post_add, color: Colors.red),
      //             onPressed: () => AcceptUpload(upload['upload_id']),
      //           ),
      //           IconButton(
      //             icon: Icon(Icons.delete, color: Colors.red),
      //             onPressed: () => deleteUpload(upload['upload_id']),
      //           ),
      //         ],
      //       ),
      //     );
      //   },
      // ),
    );
  }
}
