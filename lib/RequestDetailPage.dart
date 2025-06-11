// import 'package:farmplanning/SolutionsFormScreen%20.dart';
// import 'package:farmplanning/global.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:html' as html;

// class RequestDetailPage extends StatefulWidget {
//   final int? id;
//   RequestDetailPage({this.id});

//   @override
//   _RequestDetailPageState createState() => _RequestDetailPageState();
// }

// class _RequestDetailPageState extends State<RequestDetailPage> {
//   List<dynamic> processes = [];
//   List<dynamic> areas = [];
//   int? selectedProcessId;
//   int? creatorid;
//   TextEditingController noteController = TextEditingController();
//   TextEditingController refuseController = TextEditingController();
//   TextEditingController reasonController = TextEditingController();
//   List<String> existingImageUrls = [];
//   List<PlatformFile> newPickedImages = [];
//   bool isLoading = false;
//   int? selectedfarmId;
//   String farmText = '';
//   DateTime createdate=DateTime.now();
//   String processText = '';
//   int refuse = 0;
//   int is_refuse = 0;
//   int proplems_status = 0;
//   int problemsId = 0;
//   @override
//   void initState() {
//     super.initState();
//     fetchProcesses();
//     fetchAreas();
//     if (widget.id != null) {
//       loadData();
//     }
//   }

//   Future<void> fetchAreas() async {
//     final result = await Supabase.instance.client
//         .from('farm')
//         .select()
//         .like('farm_code', '$New_user_area2%')
//         .eq('level', 5);

//     if (!mounted) return;
//     if (result.isNotEmpty) {
//       setState(() {
//         areas = result;
//         // areas.addAll(result.map((e) => e).toList());
//       });
//     }
//   }

//   Future<void> fetchProcesses() async {
//     final response = await Supabase.instance.client
//         .from('process')
//         .select('id, process_name')
//         .eq('isdelete', 0);
//     if (!mounted) return;
//     setState(() {
//       processes = response;
//     });
//   }

//   Future<void> loadData() async {
//     final result = await Supabase.instance.client
//         .from('proplems_view_sub')
//         .select()
//         .eq('id', widget.id!);

//     final data = result;
//     if (data.isNotEmpty) {
//       if (!mounted) return;
//       setState(() {
//         selectedProcessId = data[0]['process_id'];
//         farmText = data[0]['shoet_farm_code'];
//         processText = data[0]['process_name'];
//         selectedfarmId = data[0]['farm_id'];
//         creatorid = data[0]['user_id'];
//         noteController.text = data[0]['note'] ?? '';
//         reasonController.text = data[0]['reason'] ?? '';
//         is_refuse = data[0]['is_refuse'] ?? 0;
//         proplems_status = data[0]['proplems_status'] ?? 0;
//         refuseController.text = data[0]['refuse_reason'] ?? '';
//         createdate=data[0]['created_at'] ?? '';
//         existingImageUrls = data
//             .map<String>((e) => e['pic_url'] ?? '')
//             .where((e) => e.isNotEmpty)
//             .toList();
//       });
//     }
//   }

//   String sanitizeFileName(String fileName) {
//     return fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '').replaceAll(' ', '_');
//   }

//   Future<void> uploadImages() async {
//     setState(() => isLoading = true);
//     final result = await FilePicker.platform
//         .pickFiles(allowMultiple: true, withData: true);
//     if (result != null) {
//       newPickedImages.addAll(result.files);
//     }
//     setState(() => isLoading = false);
//   }

//   Future<void> saveRefuse() async {
//     setState(() => isLoading = true);
//     await Supabase.instance.client.from('proplems').update({
//       'is_refuse': 1,
//       'refuse_reason': refuseController.text,
//     }).eq('id', widget.id!);

//     setState(() => isLoading = false);
//   }

//   Future<void> saveRequest() async {
//     setState(() => isLoading = true);

//     // int proplemId;

//     if (widget.id == null) {
//       final insertResult = await Supabase.instance.client
//           .from('proplems')
//           .insert({
//             'process_id': selectedProcessId,
//             'note': noteController.text,
//             'farm_id': selectedfarmId,
//             'user_id': user_id,
//             'reason': reasonController.text,
//           })
//           .select()
//           .single();
//       problemsId = insertResult['id'];
//     } else {
//       await Supabase.instance.client.from('proplems').update({
//         'process_id': selectedProcessId,
//         'farm_id': selectedfarmId,
//         'note': noteController.text,
//         'reason': reasonController.text,
//       }).eq('id', widget.id!);
//       problemsId = widget.id!;
//     }

//     // حذف الصور التي لم تعد موجودة
//     final currentImageUrls = [...existingImageUrls];
//     final dbImages = await Supabase.instance.client
//         .from('proplems_pic')
//         .select('pic_url')
//         .eq('proplems_id', problemsId);

//     for (var image in dbImages) {
//       if (!currentImageUrls.contains(image['pic_url'])) {
//         await Supabase.instance.client
//             .from('proplems_pic')
//             .delete()
//             .eq('proplems_id', problemsId)
//             .eq('pic_url', image['pic_url']);
//       }
//     }

//     // رفع الصور الجديدة
//     for (var file in newPickedImages) {
//       final bytes = file.bytes;
//       String cleanName = sanitizeFileName(
//           '${DateTime.now().millisecondsSinceEpoch}_${file.name}');
//       await Supabase.instance.client.storage
//           .from('proplemspic')
//           .uploadBinary(cleanName, bytes!);
//       final publicUrl = Supabase.instance.client.storage
//           .from('proplemspic')
//           .getPublicUrl(cleanName);
//       existingImageUrls.add(publicUrl);

//       await Supabase.instance.client.from('proplems_pic').upsert({
//         'proplems_id': problemsId,
//         'pic_url': publicUrl,
//       });
//     }

//     newPickedImages.clear();

//     setState(() => isLoading = false);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('تم الحفظ بنجاح')),
//     );
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Directionality(
//           textDirection: TextDirection.rtl,
//           child: Scaffold(
//             appBar: AppBar(
//               title: const Text('عرض الطلب'),
//               backgroundColor: colorbar,
//               foregroundColor: Colorapp,
//             ),
//             body: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('رقم الطلبية : $problemsId'),
//                   Text('تاريخ الانشاء: $createdate'),
import 'package:farmplanning/SolutionsFormScreen%20.dart';
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart' show DateFormat;

class RequestDetailPage extends StatefulWidget {
  final int? id;
  final int? is_finished;
  RequestDetailPage({this.id, this.is_finished});

  @override
  _RequestDetailPageState createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  List<dynamic> processes = [];
  List<dynamic> areas = [];
  int? selectedProcessId;
  int? creatorid;
  TextEditingController noteController = TextEditingController();
  TextEditingController refuseController = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  List<String> existingImageUrls = [];
  List<PlatformFile> newPickedImages = [];
  bool isLoading = false;
  int? selectedfarmId;
  String farmText = '';
  DateTime createdate = DateTime.now();
  String processText = '';
  int refuse = 0;
  int? is_refuse;
  int proplems_status = 0;
  int problemsId = 0;

  @override
  void initState() {
    super.initState();
    fetchProcesses();
    fetchAreas();
    initializeDateFormatting('ar', null).then((_) {
      setState(() {
        // بعد التهيئة يمكنك استخدام DateFormat
      });
    });
    if (widget.id != null) {
      loadData();
    }
  }

  Future<void> fetchAreas() async {
    final result = await Supabase.instance.client
        .from('farm')
        .select()
        .like('farm_code', '$New_user_area2%')
        .eq('level', 5);

    if (!mounted) return;
    if (result.isNotEmpty) {
      setState(() {
        areas = result;
      });
    }
  }

  Future<void> fetchProcesses() async {
    final response = await Supabase.instance.client
        .from('process')
        .select('id, process_name')
        .eq('isdelete', 0);
    if (!mounted) return;
    setState(() {
      processes = response;
    });
  }

  Future<void> loadData() async {
    final result = await Supabase.instance.client
        .from('proplems_view_sub')
        .select()
        .eq('id', widget.id!);

    final data = result;
    if (data.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        problemsId = data[0]['id'];
        selectedProcessId = data[0]['process_id'];
        farmText = data[0]['shoet_farm_code'];
        processText = data[0]['process_name'];
        selectedfarmId = data[0]['farm_id'];
        creatorid = data[0]['user_id'];
        noteController.text = data[0]['note'] ?? '';
        reasonController.text = data[0]['reason'] ?? '';
        is_refuse = data[0]['is_refuse'] ?? 0;
        proplems_status = data[0]['proplems_status'] ?? 0;
        refuseController.text = data[0]['refuse_reason'] ?? '';
        createdate =
            DateTime.parse(data[0]['created_at']).add(Duration(hours: 3));
        existingImageUrls = data
            .map<String>((e) => e['pic_url'] ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      });
    }
  }

  String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '').replaceAll(' ', '_');
  }

  Future<void> uploadImages() async {
    setState(() => isLoading = true);
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result != null) {
      newPickedImages.addAll(result.files);
    }
    setState(() => isLoading = false);
  }

  // Future<void> saveRefuse() async {
  //   setState(() => isLoading = true);
  //   await Supabase.instance.client.from('proplems').update({
  //     'is_refuse': 1,
  //     'refuse_reason': refuseController.text,
  //     'user_solution':user_id,
  //     'date_solution':DateTime.now(),
  //   }).eq('id', widget.id!);
  //   setState(() => isLoading = false);
  // }
Future<void> saveRefuse() async {
  setState(() => isLoading = true);

  final response = await Supabase.instance.client
      .from('proplems')
      .update({
        'is_refuse': 1,
        'proplems_status': 2,
        'refuse_reason': refuseController.text,
        'user_solution': user_id,
        'date_solution': DateTime.now().toIso8601String(),
      })
      .eq('id', widget.id!)
      .select();
await loadData();
  if (!mounted) return;

  setState(() {
    isLoading = false;
  });

  
}



  Future<void> saveFinished() async {
    setState(() => isLoading = true);
    await Supabase.instance.client.from('proplems').update({
      'is_finished': widget.is_finished,
      'user_finished': user_id,
        'date_finished': DateTime.now().toIso8601String(),
        'proplems_status': 3,
    }).eq('id', widget.id!);
    setState(() => isLoading = false);
  }

  Future<void> saveRequest() async {
    setState(() => isLoading = true);
    if (widget.id == null) {
      final insertResult = await Supabase.instance.client
          .from('proplems')
          .insert({
            'process_id': selectedProcessId,
            'note': noteController.text,
            'farm_id': selectedfarmId,
            'user_id': user_id,
            'reason': reasonController.text,
          })
          .select()
          .single();
      problemsId = insertResult['id'];
    } else {
      await Supabase.instance.client.from('proplems').update({
        'process_id': selectedProcessId,
        'farm_id': selectedfarmId,
        'note': noteController.text,
        'reason': reasonController.text,
      }).eq('id', widget.id!);
      problemsId = widget.id!;
    }

    final currentImageUrls = [...existingImageUrls];
    final dbImages = await Supabase.instance.client
        .from('proplems_pic')
        .select('pic_url')
        .eq('proplems_id', problemsId);

    for (var image in dbImages) {
      if (!currentImageUrls.contains(image['pic_url'])) {
        await Supabase.instance.client
            .from('proplems_pic')
            .delete()
            .eq('proplems_id', problemsId)
            .eq('pic_url', image['pic_url']);
      }
    }

    for (var file in newPickedImages) {
      final bytes = file.bytes;
      String cleanName = sanitizeFileName(
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await Supabase.instance.client.storage
          .from('proplemspic')
          .uploadBinary(cleanName, bytes!);
      final publicUrl = Supabase.instance.client.storage
          .from('proplemspic')
          .getPublicUrl(cleanName);
      existingImageUrls.add(publicUrl);

      await Supabase.instance.client.from('proplems_pic').upsert({
        'proplems_id': problemsId,
        'pic_url': publicUrl,
      });
    }

    newPickedImages.clear();

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('عرض الطلب'),
              backgroundColor: colorbar,
              foregroundColor: Colorapp,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          problemsId > 0
                              ? 'رقم الطلبية : $problemsId'
                              : 'طلبية جديدة',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (problemsId > 0)
                          Text(
                            'تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(createdate)}',

                            // 'تاريخ الإنشاء: ${createdate.toString().split('.')[0]}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    value: selectedProcessId,
                    items: processes.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(item['process_name']),
                      );
                    }).toList(),
                    // onChanged: (val) => setState(() => selectedProcessId = val),
                    onChanged: (val) {
                      setState(() {
                        selectedProcessId = val;
                        processText = processes.firstWhere(
                            (element) => element['id'] == val)['process_name'];
                      });
                    },
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        labelText: 'العملية',
                        labelStyle: const TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedfarmId,
                    items: areas.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(item['farm_code']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedfarmId = val;
                        farmText = areas.firstWhere(
                            (element) => element['id'] == val)['farm_code'];
                      });
                    },
                    // onChanged: (val) => setState(
                    //   () => selectedfarmId = val,
                    // ),
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        labelText: 'المزرعه',
                        labelStyle: const TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        labelText: 'عرض المشكلة',
                        labelStyle: const TextStyle(color: Colors.blue)),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        labelText: 'سبب المشكلة',
                        labelStyle: const TextStyle(color: Colors.blue)),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // معاينة الصور الحالية
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...existingImageUrls.map((url) => Stack(
                            alignment: Alignment.topRight,
                            children: [
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.network(url),
                                  ),
                                ),
                                child: Image.network(url,
                                    width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() => existingImageUrls.remove(url));
                                },
                              ),
                            ],
                          )),
                      ...newPickedImages.map((file) => Stack(
                            alignment: Alignment.topRight,
                            children: [
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.memory(file.bytes!),
                                  ),
                                ),
                                child: Image.memory(file.bytes!,
                                    width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() => newPickedImages.remove(file));
                                },
                              ),
                            ],
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if ((is_refuse == 0 || is_refuse == null) &&
                      proplems_status == 0)
                    Column(
                      children: [
                        if (creatorid == user_id || creatorid == null)
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: MainFoantcolor,
                                  foregroundColor: Colors.white),
                              onPressed: uploadImages,
                              child: const SizedBox(
                                  width: 150,
                                  height: 40,
                                  child: Center(
                                      child: Text(
                                    'تحميل صور',
                                    style: TextStyle(fontSize: 16),
                                  ))),
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (creatorid == user_id || creatorid == null)
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: color_Button,
                                  foregroundColor: Colors.white),
                              onPressed: saveRequest,
                              child: const SizedBox(
                                  width: 150,
                                  height: 40,
                                  child: Center(
                                      child: Text(
                                    'حفظ',
                                    style: TextStyle(fontSize: 16),
                                  ))),
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (user_respose['can_solution'] == 1 && problemsId > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: color_Button,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SolutionsFormScreen(
                                        farmId: selectedfarmId!,
                                        processId: selectedProcessId!,
                                        problemsId: widget.id!,
                                        farmText: farmText,
                                        processText: processText,
                                      ),
                                    ),
                                  );
                                },
                                child: const SizedBox(
                                    width: 150,
                                    height: 40,
                                    child: Center(
                                        child: Text(
                                      'تقديم حل',
                                      style: TextStyle(fontSize: 16),
                                    ))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: color_cancel,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    refuse = 1;
                                  });
                                },
                                child: const SizedBox(
                                    width: 150,
                                    height: 40,
                                    child: Center(
                                        child: Text(
                                      'رفض الطلب',
                                      style: TextStyle(fontSize: 16),
                                    ))),
                              ),
                            ],
                          ),
                        if (user_respose['can_solution'] == 1 && refuse == 1)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              TextField(
                                controller: refuseController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: 'سبب رفض الطلب',
                                  // labelStyle: TextStyle(color: Colors.blue),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: color_Button,
                                        foregroundColor: Colors.white),
                                    onPressed: () async {
                                      await saveRefuse();
                                    },
                                    child: const SizedBox(
                                        width: 150,
                                        height: 40,
                                        child: Center(
                                            child: Text(
                                          'حفظ معلومات الرفض',
                                          style: TextStyle(fontSize: 16),
                                        ))),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: color_cancel,
                                        foregroundColor: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        refuse = 0;
                                      });
                                    },
                                    child: const SizedBox(
                                        width: 150,
                                        height: 40,
                                        child: Center(
                                            child: Text(
                                          'الغاء',
                                          style: TextStyle(fontSize: 16),
                                        ))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 15),
                  Column(
                    children: [
                      if (is_refuse == 1)
                        Column(
                          children: [
                            Text('الحالة : الطلب مرفوض',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: MainFoantcolor,
                                    fontSize: 20)),
                            const SizedBox(height: 12),
                            Text('سبب الرفض : ${refuseController.text}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color_cancel,
                                    fontSize: 18)),
                          ],
                        ),
                      if (proplems_status > 0&&is_refuse == 0)
                        Column(
                          children: [
                            Text('الحالة : تم تقديم حل',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: MainFoantcolor,
                                    fontSize: 20)),
                            const SizedBox(height: 12),
                            TextButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        color_Button)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SolutionsFormScreen(
                                        farmId: selectedfarmId!,
                                        processId: selectedProcessId!,
                                        problemsId: widget.id!,
                                        farmText: farmText,
                                        processText: processText,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('عرض الحل',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 15)),
                                ))
                          ],
                        ),
                        const SizedBox(height: 15),
                      if (proplems_status ==2)
                        TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.blue)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('تأكيد'),
                                  content: Text(
                                      'هل أنت متأكد أن المشكلة تم حلها بالكامل؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('لا'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text('نعم'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await saveFinished();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('هل تم حل المشكله ؟',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 15)),
                            ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
