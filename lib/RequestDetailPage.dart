// // استورد الحزم المطلوبة
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
//   int? selectedProcessId;
//   TextEditingController noteController = TextEditingController();
//   List<String> imageUrls = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchProcesses();
//     if (widget.id != null) {
//       loadData();
//     }
//   }

//   Future<void> fetchProcesses() async {
//     final response = await Supabase.instance.client
//         .from('process')
//         .select('id, process_name');
//         if (!mounted) return;
//     setState(() {
//       processes = response;
//     });
//   }

//   Future<void> loadData() async {
//     final result = await Supabase.instance.client
//         .from('proplems_view_sub')
//         .select()
//         .eq('id', widget.id!)
//         ;
//     final data = result;
//     if (data.isNotEmpty) {
//       if (!mounted) return;
//       setState(() {
//         selectedProcessId = data[0]['process_id'];
//         noteController.text = data[0]['note'] ?? '';
//         imageUrls = data.map<String>((e) => e['pic_url'] ?? '').where((e) => e.isNotEmpty).toList();
//       });
//     }
//   }
// String sanitizeFileName(String fileName) {
//   return fileName
//       .replaceAll(RegExp(r'[^\w\s\-\.]'), '')  // remove special characters
//       .replaceAll(' ', '_');                  // replace spaces with underscores
// }

// Future<void> uploadImages() async {
//   final result = await FilePicker.platform.pickFiles(allowMultiple: true);
//   if (result != null) {
//     for (var file in result.files) {
//       final bytes = file.bytes;
//       String cleanName = sanitizeFileName('${DateTime.now().millisecondsSinceEpoch}_${file.name}');
//       final storageResponse = await Supabase.instance.client.storage
//           .from('proplemspic')
//           .uploadBinary(cleanName, bytes!);
//       final publicUrl = Supabase.instance.client.storage
//           .from('proplemspic')
//           .getPublicUrl(cleanName);
//       imageUrls.add(publicUrl);
//       print('publicUrl:$imageUrls');
//     }
//     if (!mounted) return;
//     setState(() {});
//   }
// }


//   Future<void> saveRequest() async {
//     int proplemId;
//     if (widget.id == null) {
//       final insertResult = await Supabase.instance.client
//           .from('proplems')
//           .insert({
//             'process_id': selectedProcessId,
//             'note': noteController.text,
//             'farm_id': 1 // مؤقتًا إلى أن يتم ربطها بمزرعة
//           })
//           .select()
//           .single();
//       proplemId = insertResult['id'];
//     } else {
//       await Supabase.instance.client
//           .from('proplems')
//           .update({
//             'process_id': selectedProcessId,
//             'note': noteController.text,
//           })
//           .eq('id', widget.id!);
//       proplemId = widget.id!;
//     }
// print('imageUrls:$imageUrls');
//     for (var url in imageUrls) {
//       await Supabase.instance.client
//           .from('proplems_pic')
//           .upsert({
//             'proplems_id': proplemId,
//             'pic_url': url,
//           });
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('تم الحفظ بنجاح')),
//     );
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('عرض الطلب')),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             DropdownButtonFormField<int>(
//               value: selectedProcessId,
//               items: processes.map((item) {
//                 return DropdownMenuItem<int>(
//                   value: item['id'],
//                   child: Text(item['process_name']),
//                 );
//               }).toList(),
//               onChanged: (val) => setState(() => selectedProcessId = val),
//               decoration: InputDecoration(labelText: 'العملية'),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: noteController,
//               decoration: InputDecoration(labelText: 'عرض المشكلة'),
//               maxLines: 4,
//             ),
//             SizedBox(height: 16),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: imageUrls
//                   .map((url) => Stack(
//                         alignment: Alignment.topRight,
//                         children: [
//                           Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
//                           IconButton(
//                             icon: Icon(Icons.close, color: Colors.red),
//                             onPressed: () {
//                               setState(() => imageUrls.remove(url));
//                             },
//                           ),
//                         ],
//                       ))
//                   .toList(),
//             ),
//             ElevatedButton(
//               onPressed: uploadImages,
//               child: Text('تحميل صور'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: saveRequest,
//               child: Text('حفظ'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

class RequestDetailPage extends StatefulWidget {
  final int? id;
  RequestDetailPage({this.id});

  @override
  _RequestDetailPageState createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  List<dynamic> processes = [];
  int? selectedProcessId;
  TextEditingController noteController = TextEditingController();
  List<String> existingImageUrls = [];
  List<PlatformFile> newPickedImages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProcesses();
    if (widget.id != null) {
      loadData();
    }
  }

  Future<void> fetchProcesses() async {
    final response = await Supabase.instance.client
        .from('process')
        .select('id, process_name');
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
        selectedProcessId = data[0]['process_id'];
        noteController.text = data[0]['note'] ?? '';
        existingImageUrls = data.map<String>((e) => e['pic_url'] ?? '').where((e) => e.isNotEmpty).toList();
      });
    }
  }

  String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .replaceAll(' ', '_');
  }

  Future<void> uploadImages() async {
    setState(() => isLoading = true);
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result != null) {
      newPickedImages.addAll(result.files);
    }
    setState(() => isLoading = false);
  }

  Future<void> saveRequest() async {
    setState(() => isLoading = true);

    int proplemId;

    if (widget.id == null) {
      final insertResult = await Supabase.instance.client
          .from('proplems')
          .insert({
            'process_id': selectedProcessId,
            'note': noteController.text,
            'farm_id': 1,
          })
          .select()
          .single();
      proplemId = insertResult['id'];
    } else {
      await Supabase.instance.client
          .from('proplems')
          .update({
            'process_id': selectedProcessId,
            'note': noteController.text,
          })
          .eq('id', widget.id!);
      proplemId = widget.id!;
    }

    // حذف الصور التي لم تعد موجودة
    final currentImageUrls = [...existingImageUrls];
    final dbImages = await Supabase.instance.client
        .from('proplems_pic')
        .select('pic_url')
        .eq('proplems_id', proplemId);

    for (var image in dbImages) {
      if (!currentImageUrls.contains(image['pic_url'])) {
        await Supabase.instance.client
            .from('proplems_pic')
            .delete()
            .eq('proplems_id', proplemId)
            .eq('pic_url', image['pic_url']);
      }
    }

    // رفع الصور الجديدة
    for (var file in newPickedImages) {
      final bytes = file.bytes;
      String cleanName = sanitizeFileName('${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await Supabase.instance.client.storage
          .from('proplemspic')
          .uploadBinary(cleanName, bytes!);
      final publicUrl = Supabase.instance.client.storage
          .from('proplemspic')
          .getPublicUrl(cleanName);
      existingImageUrls.add(publicUrl);

      await Supabase.instance.client
          .from('proplems_pic')
          .upsert({
            'proplems_id': proplemId,
            'pic_url': publicUrl,
          });
    }

    newPickedImages.clear();

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم الحفظ بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text('عرض الطلب')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedProcessId,
                  items: processes.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(item['process_name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedProcessId = val),
                  decoration: InputDecoration(labelText: 'العملية'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: 'عرض المشكلة'),
                  maxLines: 4,
                ),
                SizedBox(height: 16),

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
                              child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
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
                              child: Image.memory(file.bytes!, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() => newPickedImages.remove(file));
                              },
                            ),
                          ],
                        )),
                  ],
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: uploadImages,
                  child: Text('تحميل صور'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveRequest,
                  child: Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
