import 'package:farmplanning/downloadExcelTemplate.dart';
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;

class UploadExcelScreen extends StatefulWidget {
  final int type;

  const UploadExcelScreen({
    Key? key,
    required this.type,
  }) : super(key: key);
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
        .select()
        .eq('Accept_upload', widget.type)
        .eq('isdelete', 0);

    if (response.isNotEmpty) {
      if (mounted) {
        setState(() {
          uploads = response;
        });
      }
    }
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
    await supabase
        .from('data_table')
        .update({'isdelete': 1}).eq('upload_id', uploadId);
    // await supabase.from('data_table').delete().eq('upload_id', uploadId);
    fetchUploads();
  }

  Future<void> AcceptUpload(int uploadId) async {
    await supabase
        .from('data_table')
        .update({'Accept_upload': 1}).eq('upload_id', uploadId);
    fetchUploads();
  }

  Future<void> _confirmDelete(int uploadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف هذه العملية؟'),
        actions: [
          TextButton(
              child: Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(false)),
          ElevatedButton(
              child: Text('نعم، احذف'),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteUpload(uploadId);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم الحذف بنجاح')));
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // يمنع المستخدم من إغلاق النافذة يدويًا
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("جاري تحميل البيانات...",
                    style: TextStyle(fontFamily: 'myfont')),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _confirmAccept(int uploadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد القبول'),
        content: Text('هل تريد قبول هذه البيانات؟'),
        actions: [
          TextButton(
              child: Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(false)),
          ElevatedButton(
              child: Text('نعم، قبول'),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmed == true) {
      await AcceptUpload(uploadId);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم القبول بنجاح')));
    }
  }

  Future<void> uploadFromExcel() async {
    await getNextUploadId();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    // ✅ إظهار البروجرس بار
    showLoadingDialog();

    try {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      if (sheet == null) return;
      List<Map<String, dynamic>> dataToInsert = [];

      for (var row in sheet.rows.skip(1)) {
        final farmId = int.tryParse(row[0]?.value.toString() ?? '');
        final processId = int.tryParse(row[1]?.value.toString() ?? '');
        final itemId = int.tryParse(row[2]?.value.toString() ?? '');
        String? rawDate = row[3]?.value.toString();
        DateTime? parsedDate;

        if (rawDate != null) {
          try {
            parsedDate = DateTime.parse(rawDate);
          } catch (e) {
            print('فشل في تحويل التاريخ: $rawDate');
          }
        }

        final formattedDate = parsedDate != null
            ? DateFormat('yyyy-MM-dd').format(parsedDate)
            : null;
        final qty = double.tryParse(row[4]?.value.toString() ?? '');

        if (farmId == null ||
            processId == null ||
            itemId == null ||
            qty == null ||
            formattedDate == null) continue;

        dataToInsert.add({
          'farm_id': farmId,
          'process_id': processId,
          'items_id': itemId,
          'date_from': formattedDate,
          'date_to': formattedDate,
          'qty': qty,
          'upload_id': uploadId,
          'upload_date': uploadDate,
        });
      }

// بعد الانتهاء من جمع كل البيانات:
      if (dataToInsert.isNotEmpty) {
        await supabase.from('data_table').insert(dataToInsert);
      }

      await fetchUploads();

      // ✅ إغلاق البروجرس بار بعد الانتهاء
      hideLoadingDialog();

      // ✅ إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم رفع البيانات بنجاح")),
      );
    } catch (e) {
      hideLoadingDialog(); // إغلاق البروجرس في حال وجود خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء رفع البيانات")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
            if (widget.type == 0)
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
                title: Text('عملية رقم: ${upload['upload_id']}',
                    style: TextStyle(
                        color: MainFoantcolor,
                        fontSize: 18,
                        fontFamily: 'myfont')),
                subtitle: Text('تاريخ: ${upload['upload_date']}',
                    style: TextStyle(color: color_under, fontFamily: 'myfont')),
                trailing: SizedBox(
                  width: 100, // علشان الـ Row تاخد مساحة كافية
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.type == 0)
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
      ),
    );
  }
}
