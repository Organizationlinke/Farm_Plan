import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataTableScreen extends StatefulWidget {
  final String processName;
  final DateTime selectedDate;

  const DataTableScreen({
    Key? key,
    required this.processName,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _DataTableScreenState createState() => _DataTableScreenState();
}

class _DataTableScreenState extends State<DataTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<int, String?> _itemStatuses = {};
  Map<int, TextEditingController> _cancelReasons = {};
  List<Map<String, dynamic>> _items = [];
    String selectedFilter = "الكل"; // الفلتر الافتراضي

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final response = await supabase
        .from('data_table_full_view2')
        .select()
        .like('farm_code', '$New_user_area%')
        .eq('process_name', widget.processName)
        .gte('date_to', widget.selectedDate.toIso8601String())
        .lte('date_from', widget.selectedDate.toIso8601String());

    setState(() {
      _items = response as List<Map<String, dynamic>>;
      for (var item in _items) {
        _itemStatuses[item['id']] = item['finished'] == true
            ? 'finished'
            : item['under_progress'] == true
                ? 'under_progress'
                : item['cancel'] == true
                    ? 'cancel'
                    : null;
        _cancelReasons[item['id']] = TextEditingController();
      }
    });
  }
  List<Map<String, dynamic>> getFilteredItems() {
    if (selectedFilter == "الكل") return _items;
    return _items.where((item) {
      if (selectedFilter == "قيد التنفيذ") return _itemStatuses[item['id']] == 'under_progress';
      if (selectedFilter == "منتهي") return _itemStatuses[item['id']] == 'finished';
      if (selectedFilter == "ملغي") return _itemStatuses[item['id']] == 'cancel';
      return true;
    }).toList();
  }
  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('تأكيد'),
            content: Text('هل أنت متأكد أنك تريد حفظ البيانات؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }
Future<void> _saveData() async {
  for (var item in _items) {
    if (_itemStatuses[item['id']] == 'cancel' &&
        _cancelReasons[item['id']]!.text.isEmpty) {
      _showAlertDialog('خطأ', 'يجب إدخال سبب الإلغاء.');
      return;
    }
  }

  bool confirm = await _showConfirmationDialog();
  if (!confirm) return;

  try {
    for (var item in _items) {
      // if (item['is_saved'] == 0) { // ✅ تحديث فقط عندما is_saved = 0
        String? status = _itemStatuses[item['id']];
        String? stats_time = status == 'under_progress'
            ? 'under_progress_time'
            : status == 'finished'
                ? 'finished_time'
                : status == 'cancel'
                    ? 'cancel_time'
                    : 'test_time';

        DateTime now = DateTime.now();

        await supabase
            .from('data_table')
            .update({
              'under_progress': status == 'under_progress',
              'finished': status == 'finished',
              'cancel': status == 'cancel',
              stats_time: now.toIso8601String(),
              'cancel_reason': status == 'cancel' ? _cancelReasons[item['id']]!.text : null,
              // 'is_saved': 1 // 🔥 بعد الحفظ يتم تحديث is_saved إلى 1
            })
            .eq('id', item['id']) // ✅ تحديث الصف بناءً على ID
            .eq('is_saved', 0); // ✅ ضمان تحديث الصفوف غير المحفوظة فقط
      // }
    }

    _showAlertDialog('نجاح', 'تم حفظ البيانات بنجاح!');
    setState(() {
       _fetchItems();
    });
  } catch (error) {
    print(error);
    _showAlertDialog('خطأ', 'حدث خطأ أثناء حفظ البيانات.');
  }
}

  // Future<void> _saveData() async {
  //   // DateTime now = await fetchNetworkTime(); // احصل على الوقت من الإنترنت
  //   for (var item in _items) {
  //     if (_itemStatuses[item['id']] == 'cancel' &&
  //         _cancelReasons[item['id']]!.text.isEmpty) {
  //       _showAlertDialog('خطأ', 'يجب إدخال سبب الإلغاء.');
  //       return;
  //     }
  //   }

  //   bool confirm = await _showConfirmationDialog();
  //   if (!confirm) return;

  //   List<Map<String, dynamic>> updates = _items
  //   // .where((item) => item['is_saved'] == 0)
  //   .map((item) {
  //     String? status = _itemStatuses[item['id']];
  //     String? stats_time = status == 'under_progress'
  //         ? 'under_progress_time'
  //         : status == 'finished'
  //             ? 'finished_time'
  //             : status == 'cancel'
  //                 ? 'cancel_time'
  //                 : 'test_time';
  //     DateTime now = DateTime.now();
  //     return {
  //       'id': item['id'],
  //       'under_progress': status == 'under_progress',
  //       'finished': status == 'finished',
  //       'cancel': status == 'cancel',
  //       stats_time: now.toIso8601String(),
  //       'cancel_reason':
  //           status == 'cancel' ? _cancelReasons[item['id']]!.text : null,
  //           // 'is_saved':0
  //     };
  //   }).toList();

  //   try {
  //     await supabase.from('data_table').upsert(updates);
  //     _showAlertDialog('نجاح', 'تم حفظ البيانات بنجاح!');
  //   } catch (error) {
  //     print(error);
  //     _showAlertDialog('خطأ', 'حدث خطأ أثناء حفظ البيانات.');
  //   }
  // }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('موافق'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
            title:
                Text('${widget.processName} - ${widget.selectedDate.toLocal().toString().split(' ')[0]}'),
                    actions: [
            DropdownButton<String>(
              value: selectedFilter,
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
              items: ["الكل", "قيد التنفيذ", "منتهي", "ملغي"]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
            ),
          ],),
                
        body: _items.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                // itemCount: _items.length,
                  itemCount: getFilteredItems().length,
                itemBuilder: (context, index) {
                  // final item = _items[index];
                    final item = getFilteredItems()[index];
                  bool underProgressNotNull = item['under_progress_time'] != null;
                  bool cancel_notnull = item['cancel_time'] != null;
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                          '${item['items']} : ${item['qty']} ${item['unit']}'),
                      subtitle: Column(
                        children: [
                          Row(
                            children: [
                              Row(
                                children: [
                                  Text('قيد التنفيذ'),
                                  Radio<String>(
                                    value: 'under_progress',
                                    groupValue: _itemStatuses[item['id']],
                                    onChanged:user_type!=2?null: underProgressNotNull
                                        ? null
                                        : cancel_notnull
                                            ? null
                                            : (value) => setState(() =>
                                                _itemStatuses[item['id']] =
                                                    value),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('منتهي'),
                                  Radio<String>(
                                    value: 'finished',
                                    groupValue: _itemStatuses[item['id']],
                                    onChanged:user_type!=2?null: cancel_notnull
                                        ? null
                                        : underProgressNotNull
                                            ? (value) => setState(() =>
                                                _itemStatuses[item['id']] = value)
                                            : null,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('ملغي'),
                                  Radio<String>(
                                    value: 'cancel',
                                    groupValue: _itemStatuses[item['id']],
                                    onChanged:user_type!=2?null: underProgressNotNull
                                        ? null
                                        : (value) => setState(() =>
                                            _itemStatuses[item['id']] = value),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_itemStatuses[item['id']] == 'cancel')
                            TextField(
                              controller: _cancelReasons[item['id']],
                              decoration:
                                  InputDecoration(labelText: 'سبب الإلغاء'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton:user_type==2? FloatingActionButton(
         
          onPressed: _saveData,
          child: Icon(Icons.save),
          
        ):null,
      ),
    );
  }
}

// import 'package:farmplanning/global.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class DataTableScreen extends StatefulWidget {
//   final String processName;
//   final DateTime selectedDate;
//   // final String New_user_area;

//   const DataTableScreen({
//     Key? key,
//     required this.processName,
//     required this.selectedDate,
//     // required this.New_user_area,
//   }) : super(key: key);

//   @override
//   _DataTableScreenState createState() => _DataTableScreenState();
// }

// class _DataTableScreenState extends State<DataTableScreen> {
//   final SupabaseClient supabase = Supabase.instance.client;
//   Map<int, String?> _itemStatuses = {};
//   List<Map<String, dynamic>> _items = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchItems();
//   }
//     Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: widget.selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );

//     if (picked != null) {
//       setState(() {
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DataTableScreen(
//               selectedDate: picked,
//               processName: widget.processName,
//             ),
//           ),
//         );
//       });
//     }
//   }

//   Future<void> _fetchItems() async {
//     final response = await supabase
//         .from('data_table_full_view2')
//         .select()
//         .eq('process_name', widget.processName)
//         .like('farm_code', '$New_user_area%')
//         .gte('date_to', widget.selectedDate.toIso8601String())
//         .lte('date_from', widget.selectedDate.toIso8601String());

//     setState(() {
//       _items = response as List<Map<String, dynamic>>;
//       for (var item in _items) {
//         if (item['finished'] == true) {
//           _itemStatuses[item['id']] = 'finished';
//         } else if (item['under_progress'] == true) {
//           _itemStatuses[item['id']] = 'under_progress';
//         } else if (item['cancel'] == true) {
//           _itemStatuses[item['id']] = 'cancel';
//         } else {
//           _itemStatuses[item['id']] = null;
//         }
//       }
//     });
//   }

//   Future<void> _saveData() async {
//     // if (_itemStatuses.values.any((status) => status == null)) {
//     //   _showAlertDialog('خطأ', 'يجب تحديد حالة لجميع العناصر قبل الحفظ.');
//     //   return;
//     // }

//     bool confirm = await _showConfirmationDialog();
//     if (!confirm) return;

//     List<Map<String, dynamic>> updates = _items.map((item) {
//       String? status = _itemStatuses[item['id']];
//       return {
//         'id': item['id'],
//         'under_progress': status == 'under_progress',
//         'finished': status == 'finished',
//         'cancel': status == 'cancel',
//       };
//     }).toList();

//     try {
//       await supabase.from('data_table').upsert(updates);
//       _showAlertDialog('نجاح', 'تم حفظ البيانات بنجاح!');
//     } catch (error) {
//       _showAlertDialog('خطأ', 'حدث خطأ أثناء حفظ البيانات.');
//     }
//   }

//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text('تأكيد'),
//             content: Text('هل أنت متأكد من حفظ التغييرات؟'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: Text('إلغاء'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: Text('موافق'),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   void _showAlertDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('موافق'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           // title: Text('إدارة البيانات')),
//            title: GestureDetector(
//             onTap: () => _selectDate(context),
//             child: Text(
//               '${widget.processName} : ${widget.selectedDate.toLocal().toString().split(' ')[0]}',
//             ),
//           ),
//         ),
//         body: _items.isEmpty
//             ? Center(child: CircularProgressIndicator())
//             : ListView.builder(
//                 itemCount: _items.length,
//                 itemBuilder: (context, index) {
//                   final item = _items[index];
//                   return Card(
//                     margin: EdgeInsets.all(10),
//                     child: ListTile(
//                       title: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                               '${item['items']} : ${item['qty']} ${item['unit']}',
//                               style: const TextStyle(
//                                   color: Color.fromARGB(255, 23, 1, 119))),
//                           Text(item['shoet_farm_code'],
//                               style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Color.fromARGB(255, 0, 108, 197))),
//                         ],
//                       ),
//                       // Text(item['name'] ?? 'بدون اسم'),
//                       subtitle: Row(
//                        mainAxisAlignment:MainAxisAlignment.spaceBetween,
//                         children: [
            
//                           Row(
//                             children: [
//                                const Text('قيد التنفيذ'),
//                               Radio<String>(
//                                 // title: Text('قيد التنفيذ'),
//                                activeColor: Colors.amber,
//                                 value: 'under_progress',
//                                 groupValue: _itemStatuses[item['id']],
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _itemStatuses[item['id']] = value;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               const Text('منتهي'),
//                               Radio<String>(
//                                 activeColor: Colors.green,
//                                 value: 'finished',
//                                 groupValue: _itemStatuses[item['id']],
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _itemStatuses[item['id']] = value;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               const Text('ملغي'),
//                               Radio<String>(
//                                 // title: Text('ملغي'),
//                                 activeColor: Colors.red,
//                                 value: 'cancel',
//                                 groupValue: _itemStatuses[item['id']],
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _itemStatuses[item['id']] = value;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: _saveData,
//           child: Icon(Icons.save),
//         ),
//       ),
//     );
//   }
// }
