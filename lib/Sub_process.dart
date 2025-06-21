// import 'package:farmplanning/global.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class DataTableScreen extends StatefulWidget {
//   final String processName;
//   final DateTime selectedDate;
//   final bool checkdate;

//   const DataTableScreen({
//     Key? key,
//     required this.processName,
//     required this.selectedDate,
//     required this.checkdate,
//   }) : super(key: key);

//   @override
//   _DataTableScreenState createState() => _DataTableScreenState();
// }

// class _DataTableScreenState extends State<DataTableScreen> {
//   final SupabaseClient supabase = Supabase.instance.client;
//   Map<int, String?> _itemStatuses = {};
//   Map<int, TextEditingController> _cancelReasons = {};
//   List<Map<String, dynamic>> _items = [];
//   String selectedFilter = "الكل"; // الفلتر الافتراضي
//   DateTime? currentDate;
//   Map<int, TextEditingController> _processcontroller = {};
//   Map<int, String?> _userKpi = {}; // التقييم لكل عملية
//   Map<int, TextEditingController> _kpiReasons = {}; // سبب التقييم إذا كان "سيئ"

//   Map<int, String?> _sectorKpi = {};
//   Map<int, TextEditingController> _sectorKpiReasons = {};

//   Map<int, String?> _areaKpi = {};
//   Map<int, TextEditingController> _areaKpiReasons = {};

//   Map<int, String?> _qualityKpi = {};
//   Map<int, TextEditingController> _qualityKpiReasons = {};
//   static const String exlant='ممتاز';
//   static const String verygood='جيد جدًا';
//   static const String good='جيد';
//   static const String well='مقبول';
//   static const String bad='سيئ';

//   final _cancel_reason = TextEditingController();
//   @override
//   void initState() {
//     super.initState();
//     _fetchItems();
//     getCurrentDateFromSupabase();
//   }

//   int selectedStars = 0;

//   static const Map<int, String> kpiLabels = {
//     5: exlant,
//     4: verygood,
//     3: good,
//     2: well,
//     1: bad,
//   };

//   int _getKpiStarCount(String? value) {
//     switch (value) {
//       case exlant:
//         return 5;
//       case verygood:
//         return 4;
//       case good:
//         return 3;
//       case well:
//         return 2;
//       case bad:
//         return 1;
//       default:
//         return 0;
//     }
//   }

//   Future<DateTime?> getCurrentDateFromSupabase() async {
//     try {
//       final response = await supabase
//           .rpc('get_server_time'); // استدعاء دالة SQL نصنعها يدويًا
//       if (response != null) {
//         currentDate =
//             DateTime.parse(response.toString()).add(Duration(hours: 2));
//         print(currentDate);
//         return DateTime.parse(response.toString());
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//     return null;
//   }

//   Future<void> _fetchItems() async {
//     final response = await supabase
//         .from('data_table_full_view2')
//         .select()
//         .like('farm_code', '$New_user_area%')
//         .eq('process_name', widget.processName)
//         .gte('date_to', widget.selectedDate.toIso8601String())
//         .lte('date_from', widget.selectedDate.toIso8601String());
//     setState(() {
//       _items = response as List<Map<String, dynamic>>;
//       for (var item in _items) {
//         int id = item['id'];
//         _itemStatuses[id] = item['finished'] == true
//             ? 'finished'
//             : item['under_progress'] == true
//                 ? 'under_progress'
//                 : item['cancel'] == true
//                     ? 'cancel'
//                     : null;

//         _cancelReasons[id] =
//             TextEditingController(text: item['cancel_reason'] ?? '');
//         _processcontroller[id] =
//             TextEditingController(text: item['actual_qty']?.toString() ?? '');

//         _userKpi[id] = item['user_kpi']; // التقييم السابق لو موجود
//         _kpiReasons[id] =
//             TextEditingController(text: item['user_kpi_reason'] ?? '');
//         _sectorKpi[id] = item['sector_kpi'];
//         _sectorKpiReasons[id] =
//             TextEditingController(text: item['sector_kpi_reason'] ?? '');

//         _areaKpi[id] = item['area_kpi'];
//         _areaKpiReasons[id] =
//             TextEditingController(text: item['area_kpi_reason'] ?? '');

//         _qualityKpi[id] = item['quality_kpi'];
//         _qualityKpiReasons[id] =
//             TextEditingController(text: item['quality_kpi_reason'] ?? '');
//       }
//     });
//   }

//   List<Map<String, dynamic>> getFilteredItems() {
//     if (selectedFilter == "الكل") return _items;
//     return _items.where((item) {
//       if (selectedFilter == "قيد التنفيذ")
//         return _itemStatuses[item['id']] == 'under_progress';
//       if (selectedFilter == "منتهي")
//         return _itemStatuses[item['id']] == 'finished';
//       if (selectedFilter == "ملغي")
//         return _itemStatuses[item['id']] == 'cancel';
//       return true;
//     }).toList();
//   }

//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text('تأكيد'),
//             content: Text('هل أنت متأكد أنك تريد حفظ البيانات؟'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: Text('إلغاء'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: Text('تأكيد'),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   Future<void> _saveData() async {
//     if (!widget.checkdate) {
//       _showAlertDialog('خطأ', 'لا يتم الحفظ الا علي تاريخ اليوم فقط.');
//       return;
//     }
//     for (var item in _items) {
//       if (_itemStatuses[item['id']] == 'cancel' &&
//           _cancelReasons[item['id']]!.text.isEmpty) {
//         _showAlertDialog('خطأ', 'يجب إدخال سبب الإلغاء.');
//         return;
//       }
//       if (item['process_id'] == 5 &&
//           _processcontroller[item['id']]!.text.isEmpty &&
//           _itemStatuses[item['id']] == 'finished') {
//         _showAlertDialog('خطأ', 'يجب إدخال عدد ساعات الري الفعليه.');
//         return;
//       }
//     }

//     bool confirm = await _showConfirmationDialog();
//     if (!confirm) return;

//     try {
//       for (var item in _items) {
//         String? kpi = _userKpi[item['id']];
//         String? kpiReason = _kpiReasons[item['id']]?.text;
// // تحقق من ملء السبب إذا كان التقييم سيئ
//         if (_itemStatuses[item['id']] == 'finished' &&
//             kpi == bad &&
//             (kpiReason == null || kpiReason.isEmpty)) {
//           _showAlertDialog(
//               'خطأ', 'يرجى إدخال سبب التقييم السيئ للعملية ${item['items']}');
//           return;
//         }
//         // if (item['is_saved'] == 0) { // ✅ تحديث فقط عندما is_saved = 0
//         String? status = _itemStatuses[item['id']];
//         String? stats_time = status == 'under_progress'
//             ? 'under_progress_time'
//             : status == 'finished'
//                 ? 'finished_time'
//                 : status == 'cancel'
//                     ? 'cancel_time'
//                     : 'test_time';

//         String? stats_user = status == 'under_progress'
//             ? 'user_under_progress'
//             : status == 'finished'
//                 ? 'user_finished'
//                 : status == 'cancel'
//                     ? 'user_cancel'
//                     : 'user_test';

//         DateTime now = DateTime.now();

//         await supabase
//             .from('data_table')
//             .update({
//               'under_progress': status == 'under_progress',
//               'finished': status == 'finished',
//               'cancel': status == 'cancel',
//               stats_time: now.toIso8601String(),
//               stats_user: user_id,
//               'cancel_reason':
//                   status == 'cancel' ? _cancelReasons[item['id']]!.text : null,
//               'actual_qty': item['process_id'] == 5 &&
//                       _itemStatuses[item['id']] == 'finished'
//                   ? _processcontroller[item['id']]!.text
//                   : item['qty_balance'],
//               'out_source': item['out_source'] ?? false, // ✅ أضف هذا السطر

//               // 'is_saved': 1 // 🔥 بعد الحفظ يتم تحديث is_saved إلى 1
//             })
//             .eq('id', item['id']) // ✅ تحديث الصف بناءً على ID
//             .eq('is_saved', 0); // ✅ ضمان تحديث الصفوف غير المحفوظة فقط
//         // }
//         if (user_respose['user_kpi_type'] == 1) {
//           await supabase
//               .from('data_table')
//               .update({
//                 'user_kpi': _userKpi[item['id']],
//                 'user_kpi_reason': _userKpi[item['id']] == bad|| _userKpi[item['id']] == well
//                     ? _kpiReasons[item['id']]?.text
//                     : null,
//                 'user_id_kpi': user_id,
//               })
//               .eq('id', item['id'])
//               .filter('user_kpi', 'is', null);
//         }
//         if (user_respose['user_kpi_type'] == 2) {
//           await supabase
//               .from('data_table')
//               .update({
//                 'sector_kpi': _sectorKpi[item['id']],
//                 'sector_kpi_reason': _sectorKpi[item['id']] == bad|| _sectorKpi[item['id']] == well
//                     ? _sectorKpiReasons[item['id']]?.text
//                     : null,
//                 'sector_userid_kpi': user_id,
//               })
//               .eq('id', item['id'])
//               .filter('sector_kpi', 'is', null);
//         }
//         if (user_respose['user_kpi_type'] == 3) {
//           await supabase
//               .from('data_table')
//               .update({
//                 'area_kpi': _areaKpi[item['id']],
//                 'area_kpi_reason': _areaKpi[item['id']] == bad|| _areaKpi[item['id']] == well
//                     ? _areaKpiReasons[item['id']]?.text
//                     : null,
//                 'area_userid_kpi': user_id,
//               })
//               .eq('id', item['id'])
//               .filter('area_kpi', 'is', null);
//         }
//         if (user_respose['user_kpi_type'] == 4) {
//           await supabase
//               .from('data_table')
//               .update({
//                 'quality_kpi': _qualityKpi[item['id']],
//                 'quality_kpi_reason': _qualityKpi[item['id']] == bad|| _qualityKpi[item['id']] == well
//                     ? _qualityKpiReasons[item['id']]?.text
//                     : null,
//                 'quality_userid_kpi': user_id,
//               })
//               .eq('id', item['id'])
//               .filter('quality_kpi', 'is', null);
//         }
//       }

//       _showAlertDialog('نجاح', 'تم حفظ البيانات بنجاح!');
//       setState(() {
//         _fetchItems();
//       });
//     } catch (error) {
//       print(error);
//       _showAlertDialog('خطأ', 'حدث خطأ أثناء حفظ البيانات.');
//     }
//   }

//   void _showAlertDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context), child: Text('موافق'))
//         ],
//       ),
//     );
//   }

//   Future<bool?> _showDatePickerAndTransfer(Map<String, dynamic> item,
//       {required bool fullTransfer}) async {
//     DateTime selectedDate = DateTime.now();
//     TextEditingController qtyController = TextEditingController();

//     return await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: Text(
//             fullTransfer ? 'ترحيل العملية' : 'ترحيل جزء من العملية',
//             textAlign: TextAlign.center,
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(
//                 width: 500,
//               ),
//               Text('التاريخ', textAlign: TextAlign.center),
//               SizedBox(
//                 height: 15,
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   DateTime? picked = await showDatePicker(
//                     context: dialogContext, // استخدم سياق الـ dialog
//                     initialDate: selectedDate,
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime(2100),
//                   );
//                   if (picked != null) {
//                     setState(() {
//                       selectedDate = picked;
//                     });
//                   }
//                 },
//                 child: Text(
//                   '${selectedDate.toLocal()}'.split(' ')[0],
//                 ),
//               ),
//               if (!fullTransfer)
//                 SizedBox(
//                   height: 15,
//                 ),
//               if (!fullTransfer)
//                 Directionality(
//                   textDirection: TextDirection.rtl,
//                   child: TextField(
//                     textAlign: TextAlign.center,
//                     controller: qtyController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText:
//                           'أدخل الكمية المتبقية (متاح كمية ${item['qty_balance']} ${item['unit']} فقط)',
//                     ),
//                   ),
//                 ),
//               SizedBox(
//                 height: 15,
//               ),
//             ],
//           ),
//           actions: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext, false),
//                   child: Text('إلغاء'),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     double enteredQty =
//                         double.tryParse(qtyController.text) ?? 0.0;
//                     double qtyBalance = item['qty_balance'] ?? 0.0;

//                     if (!fullTransfer && enteredQty > qtyBalance) {
//                       ScaffoldMessenger.of(dialogContext).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                               'الكمية المدخلة لا يجب أن تتجاوز الرصيد المتبقي (${qtyBalance.toStringAsFixed(2)}).'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                       return;
//                     }

//                     try {
//                       print('بدأ الحفظ...');
//                       _saveTransferData(
//                         item,
//                         selectedDate,
//                         fullTransfer ? item['qty'] : enteredQty,
//                         fullTransfer ? 'Full' : 'Part',
//                       );
//                       print('تم الحفظ');

//                       // أغلق الديالوج بشكل آمن بعد الانتظار
//                       if (dialogContext.mounted) {
//                         Navigator.of(dialogContext).pop(true);
//                         print('تم إغلاق الديالوج');
//                       }
//                     } catch (e) {
//                       print("خطأ أثناء الحفظ: $e");
//                       ScaffoldMessenger.of(dialogContext).showSnackBar(
//                         SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
//                       );
//                     }
//                   },
//                   child: Text('موافق'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _saveTransferData(Map<String, dynamic> item, DateTime date,
//       double qty, String post_type) async {
//     await supabase.from('data_table').upsert({
//       'date_from': date.toIso8601String(),
//       'date_to': date.toIso8601String(),
//       'process_id': item['process_id'],
//       'items_id': item['items_id'],
//       'qty': qty,
//       'farm_id': item['farm_id'],
//       'old_id': item['id'],
//       'user_post': user_id,
//       'post_type': post_type
//     });
//     _showAlertDialog('نجاح', 'تم الترحيل بنجاح');
//   }

//   Widget buildKpiSection({
//     required int itemId,
//     required String title,
//     required Map<int, String?> kpiMap,
//     required Map<int, TextEditingController> reasonMap,
//     required Function(String?) onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
//         Row(
//           children: List.generate(5, (index) {
//             final starNumber = index + 1;
//             return IconButton(
//               padding: EdgeInsets.zero,
//               constraints: BoxConstraints(),
//               icon: Icon(
//                 Icons.star,
//                 color: starNumber <= _getKpiStarCount(kpiMap[itemId])
//                     ? Colors.amber
//                     : Colors.grey[300],
//               ),
//               onPressed: () => onChanged(kpiLabels[starNumber]),
//             );
//           }),
//         ),
//         if (kpiMap[itemId] != null)
//           Text(kpiMap[itemId]!,
//               style: TextStyle(fontSize: 14, color: Colors.blue)),
//         if (kpiMap[itemId] == bad || kpiMap[itemId] == well)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: TextField(
//               controller: reasonMap[itemId],
//               decoration: InputDecoration(
//                 labelText: kpiMap[itemId] == bad
//                     ? 'سبب التقييم السيئ'
//                     : 'سبب التقييم المقبول',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 1,
//             ),
//           ),
//       ],
//     );
//   }

//   Widget buildKpiRowItem({
//     required int itemId,
//     required String title,
//     required Map<int, String?> kpiMap,
//     required Map<int, TextEditingController> reasonMap,
//     required Function(String?) onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(title,
//               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: List.generate(5, (index) {
//               final starNumber = index + 1;
//               return IconButton(
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(),
//                 icon: Icon(
//                   Icons.star,
//                   size: 20,
//                   color: starNumber <= _getKpiStarCount(kpiMap[itemId])
//                       ? Colors.amber
//                       : Colors.grey[300],
//                 ),
//                 onPressed: () => onChanged(kpiLabels[starNumber]),
//               );
//             }),
//           ),
//           if (kpiMap[itemId] != null)
//             Text(kpiMap[itemId]!,
//                 style: TextStyle(fontSize: 10, color: Colors.blue)),
//           if (kpiMap[itemId] == bad || kpiMap[itemId] == well)
//             SizedBox(
//               width: 100,
//               child: TextField(
//                 controller: reasonMap[itemId],
//                 decoration: InputDecoration(
//                   labelText: 'السبب',
//                   border: OutlineInputBorder(),
//                   isDense: true,
//                 ),
//                 maxLines: 1,
//                 style: TextStyle(fontSize: 10),
//               ),
//             ),
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
//           backgroundColor: colorbar,
//           foregroundColor: Colorapp,
//           title: Text(
//               '${widget.processName} - ${widget.selectedDate.toLocal().toString().split(' ')[0]}'),
//           actions: [
//             DropdownButton<String>(
//               value: selectedFilter,
//               onChanged: (value) {
//                 setState(() {
//                   selectedFilter = value!;
//                 });
//               },
//               items: ["الكل", "قيد التنفيذ", "منتهي", "ملغي"]
//                   .map((status) => DropdownMenuItem(
//                         value: status,
//                         child: Text(status),
//                       ))
//                   .toList(),
//             ),
//           ],
//         ),
//         body: _items.isEmpty
//             ? Center(child: CircularProgressIndicator())
//             : ListView.builder(
//                 // itemCount: _items.length,
//                 itemCount: getFilteredItems().length,
//                 itemBuilder: (context, index) {
//                   // final item = _items[index];
//                   final item = getFilteredItems()[index];
//                   bool underProgressNotNull =
//                       item['under_progress_time'] != null;
//                   bool cancel_notnull = item['cancel_time'] != null;

//                   return Card(
//                     margin: EdgeInsets.all(10),
//                     child: ListTile(
//                       title: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Text(
//                                   '${item['items']} : ${item['qty']} ${item['unit']}',
//                                   style: TextStyle(color: MainFoantcolor)),
//                               SizedBox(
//                                 width: 15,
//                               ),
//                               if (item['is_out_source'] == 1 &&
//                                   item['qty_balance'] > 0)
//                                 Row(
//                                   children: [
//                                     Text(
//                                       'عماله خارجية',
//                                       style: TextStyle(color: color_under),
//                                     ),
//                                     Checkbox(
//                                       value: item['out_source'] ?? false,
//                                       onChanged: _itemStatuses[item['id']] ==
//                                               'finished'
//                                           ? null
//                                           : (val) {
//                                               setState(() {
//                                                 item['out_source'] = val!;
//                                               });
//                                             },
//                                     ),
//                                   ],
//                                 ),
//                               if (item['process_id'] == 5 &&
//                                   _itemStatuses[item['id']] == 'finished' &&
//                                   item['qty_balance'] > 0)
//                                 SizedBox(
//                                   width: 150,
//                                   child: TextField(
//                                     controller: _processcontroller[item['id']],
//                                     keyboardType:
//                                         TextInputType.numberWithOptions(
//                                             decimal: true),
//                                     inputFormatters: [
//                                       FilteringTextInputFormatter.allow(
//                                           RegExp(r'^\d*\.?\d{0,}$')),
//                                     ],
//                                     decoration: InputDecoration(
//                                       labelText: 'كمية الري الفعلية',
//                                     ),
//                                   ),
//                                 ),
//                               if (item['qty_balance'] == 0 && item['qty'] > 0)
//                                 Text(
//                                   'العملية مُرحله',
//                                   style: TextStyle(
//                                       color: Colors.grey, fontSize: 12),
//                                 ),
//                               if (item['qty_balance'] < item['qty'] &&
//                                   item['qty_balance'] > 0)
//                                 Text(
//                                   'باقي كمية :${item['qty_balance']}',
//                                   style: TextStyle(
//                                       color: Colors.grey, fontSize: 12),
//                                 ),
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               Text(item['shoet_farm_code'],
//                                   style: TextStyle(
//                                       color: Colors.blue, fontSize: 12)),
//                               PopupMenuButton<String>(
//                                 icon: Icon(
//                                   Icons.more_vert,
//                                   color: MainFoantcolor,
//                                 ),
//                                 onSelected: (value) async {
//                                   bool? result;

//                                   if (value == 'full_transfer') {
//                                     result = await _showDatePickerAndTransfer(
//                                         item,
//                                         fullTransfer: true);
//                                   } else if (value == 'partial_transfer') {
//                                     result = await _showDatePickerAndTransfer(
//                                         item,
//                                         fullTransfer: false);
//                                     print('result::$result');
//                                   }

//                                   if (result == true) {
//                                     await _fetchItems();

//                                     setState(() {});
//                                   }
//                                 },

//                                 itemBuilder: (context) => [
//                                   if (user_respose['can_post'] == 1 &&
//                                       _itemStatuses[item['id']] == null &&
//                                       item['qty_balance'] == item['qty'])
//                                     PopupMenuItem(
//                                       value: 'full_transfer',
//                                       child: Text('ترحيل العملية'),
//                                     ),
//                                   if (user_respose['can_post'] == 1 &&
//                                       item['qty_balance'] > 0 &&
//                                       (_itemStatuses[item['id']] == null ||
//                                           _itemStatuses[item['id']] ==
//                                               'under_progress'))
//                                     PopupMenuItem(
//                                       value: 'partial_transfer',
//                                       child: Text('ترحيل جزء من العملية'),
//                                     ),
//                                 ],
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                       subtitle: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Row(
//                                 children: [
//                                   Text(
//                                     'قيد التنفيذ',
//                                     style: TextStyle(color: color_under),
//                                   ),
//                                   Radio<String>(
//                                     value: 'under_progress',
//                                     activeColor: color_under,
//                                     groupValue: _itemStatuses[item['id']],
//                                     onChanged: user_type != 2 ||
//                                             item['qty_balance'] == 0
//                                         ? null
//                                         : underProgressNotNull
//                                             ? null
//                                             : cancel_notnull
//                                                 ? null
//                                                 : (value) => setState(() =>
//                                                     _itemStatuses[item['id']] =
//                                                         value),
//                                   ),
//                                 ],
//                               ),
//                               Row(
//                                 children: [
//                                   Text('منتهي',
//                                       style: TextStyle(color: color_finish)),
//                                   Radio<String>(
//                                     value: 'finished',
//                                     activeColor: color_finish,
//                                     groupValue: _itemStatuses[item['id']],
//                                     onChanged: user_type != 2 ||
//                                             item['qty_balance'] == 0
//                                         ? null
//                                         : cancel_notnull
//                                             ? null
//                                             : underProgressNotNull
//                                                 ? (value) => setState(() =>
//                                                     _itemStatuses[item['id']] =
//                                                         value)
//                                                 : null,
//                                   ),
//                                 ],
//                               ),
//                               Row(
//                                 children: [
//                                   Text('ملغي',
//                                       style: TextStyle(color: color_cancel)),
//                                   Radio<String>(
//                                     value: 'cancel',
//                                     activeColor: color_cancel,
//                                     groupValue: _itemStatuses[item['id']],
//                                     onChanged: user_type != 2 ||
//                                             item['qty_balance'] == 0
//                                         ? null
//                                         : underProgressNotNull
//                                             ? null
//                                             : (value) => setState(() =>
//                                                 _itemStatuses[item['id']] =
//                                                     value),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           if (_itemStatuses[item['id']] == 'cancel')
//                             TextField(
//                               controller: _cancelReasons[item['id']],
//                               decoration:
//                                   InputDecoration(labelText: 'سبب الإلغاء'),
//                             ),

//                           if (_itemStatuses[item['id']] == 'finished') ...[
//                             Row(
//                               children: [
//                                 if (user_respose['user_kpi_type'] == 1 ||
//                                     _userKpi[item['id']] != null)
//                                   Expanded(
//                                     child: buildKpiSection(
//                                       itemId: item['id'],
//                                       title: 'تقييم المهندس',
//                                       kpiMap: _userKpi,
//                                       reasonMap: _kpiReasons,
//                                       onChanged: (val) => setState(
//                                           () => _userKpi[item['id']] = val),
//                                     ),
//                                   ),
//                                 SizedBox(width: 8),
//                                 if (user_respose['user_kpi_type'] == 2 ||
//                                     _sectorKpi[item['id']] != null)
//                                   Expanded(
//                                     child: buildKpiSection(
//                                       itemId: item['id'],
//                                       title: 'تقييم مدير القطاع',
//                                       kpiMap: _sectorKpi,
//                                       reasonMap: _sectorKpiReasons,
//                                       onChanged: (val) => setState(
//                                           () => _sectorKpi[item['id']] = val),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                             Row(
//                               children: [
//                                 if (user_respose['user_kpi_type'] == 3 ||
//                                     _areaKpi[item['id']] != null)
//                                   Expanded(
//                                     child: buildKpiSection(
//                                       itemId: item['id'],
//                                       title: 'تقييم مدير المنطقة',
//                                       kpiMap: _areaKpi,
//                                       reasonMap: _areaKpiReasons,
//                                       onChanged: (val) => setState(
//                                           () => _areaKpi[item['id']] = val),
//                                     ),
//                                   ),
//                                 SizedBox(width: 8),
//                                 if (user_respose['user_kpi_type'] == 4)
//                                   Expanded(
//                                     child: buildKpiSection(
//                                       itemId: item['id'],
//                                       title: 'تقييم اللجنة الفنية',
//                                       kpiMap: _qualityKpi,
//                                       reasonMap: _qualityKpiReasons,
//                                       onChanged: (val) => setState(
//                                           () => _qualityKpi[item['id']] = val),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//         floatingActionButton: user_type == 2
//             ? FloatingActionButton(
//                 onPressed: _saveData,
//                 child: Icon(Icons.save),
//               )
//             : null,
//       ),
//     );
//   }
// }
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataTableScreen extends StatefulWidget {
  final String processName;
  final DateTime selectedDate;
  final bool checkdate;

  const DataTableScreen({
    Key? key,
    required this.processName,
    required this.selectedDate,
    required this.checkdate,
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
  DateTime? currentDate;
  Map<int, TextEditingController> _processcontroller = {};
  Map<int, String?> _userKpi = {}; // التقييم لكل عملية
  Map<int, TextEditingController> _kpiReasons = {}; // سبب التقييم
  bool _isSaving = false;

  Map<int, String?> _sectorKpi = {};
  Map<int, TextEditingController> _sectorKpiReasons = {};

  Map<int, String?> _areaKpi = {};
  Map<int, TextEditingController> _areaKpiReasons = {};

  Map<int, String?> _qualityKpi = {};
  Map<int, TextEditingController> _qualityKpiReasons = {};

  static const String exlant = 'ممتاز';
  static const String verygood = 'جيد جدًا';
  static const String good = 'جيد';
  static const String well = 'مقبول';
  static const String bad = 'سيئ';

  final _cancel_reason = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchItems();
    getCurrentDateFromSupabase();
  }

  int selectedStars = 0;

  static const Map<int, String> kpiLabels = {
    5: exlant,
    4: verygood,
    3: good,
    2: well,
    1: bad,
  };

  int _getKpiStarCount(String? value) {
    switch (value) {
      case exlant:
        return 5;
      case verygood:
        return 4;
      case good:
        return 3;
      case well:
        return 2;
      case bad:
        return 1;
      default:
        return 0;
    }
  }

  Future<DateTime?> getCurrentDateFromSupabase() async {
    try {
      final response = await supabase
          .rpc('get_server_time'); //استدعاء دالة SQL نصنعها يدويًا
      if (response != null) {
        currentDate =
            DateTime.parse(response.toString()).add(Duration(hours: 2));
        print(currentDate);
        return DateTime.parse(response.toString());
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
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
        int id = item['id'];
        _itemStatuses[id] = item['finished'] == true
            ? 'finished'
            : item['under_progress'] == true
                ? 'under_progress'
                : item['cancel'] == true
                    ? 'cancel'
                    : null;

        _cancelReasons[id] =
            TextEditingController(text: item['cancel_reason'] ?? '');
        _processcontroller[id] =
            TextEditingController(text: item['actual_qty']?.toString() ?? '');

        _userKpi[id] = item['user_kpi']; // التقييم السابق لو موجود
        _kpiReasons[id] =
            TextEditingController(text: item['user_kpi_reason'] ?? '');
        _sectorKpi[id] = item['sector_kpi'];
        _sectorKpiReasons[id] =
            TextEditingController(text: item['sector_kpi_reason'] ?? '');

        _areaKpi[id] = item['area_kpi'];
        _areaKpiReasons[id] =
            TextEditingController(text: item['area_kpi_reason'] ?? '');

        _qualityKpi[id] = item['quality_kpi'];
        _qualityKpiReasons[id] =
            TextEditingController(text: item['quality_kpi_reason'] ?? '');
      }
    });
  }

  List<Map<String, dynamic>> getFilteredItems() {
    if (selectedFilter == "الكل") return _items;
    return _items.where((item) {
      if (selectedFilter == "قيد التنفيذ")
        return _itemStatuses[item['id']] == 'under_progress';
      if (selectedFilter == "منتهي")
        return _itemStatuses[item['id']] == 'finished';
      if (selectedFilter == "ملغي")
        return _itemStatuses[item['id']] == 'cancel';
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

  // Future<void> _saveData() async {
  //   try {} catch (e) {}
  //   if (!widget.checkdate) {
  //     _showAlertDialog('خطأ', 'لا يتم الحفظ الا علي تاريخ اليوم فقط.');
  //     return;
  //   }
  //   // --- بداية التعديل ---
  //   for (var item in _items) {
  //     int id = item['id'];
  //     String? status = _itemStatuses[id];

  //     if (status == 'cancel' && _cancelReasons[id]!.text.isEmpty) {
  //       _showAlertDialog(
  //           'خطأ', 'يجب إدخال سبب الإلغاء للعنصر ${item['items']}.');
  //       return;
  //     }
  //     if (item['process_id'] == 5 &&
  //         _processcontroller[id]!.text.isEmpty &&
  //         status == 'finished') {
  //       _showAlertDialog('خطأ', 'يجب إدخال عدد ساعات الري الفعليه.');
  //       return;
  //     }

  //     if (status == 'finished') {
  //       // الشرط الأول: التحقق من وجود تقييم إذا كان user_kpi_type == 1
  //       if (user_respose['user_kpi_type'] == 1 && _userKpi[id] == null) {
  //         _showAlertDialog(
  //             'خطأ', 'يجب تسجيل تقييم المهندس أولاً للعنصر ${item['items']}.');
  //         return;
  //       }

  //       // الشرط الثاني: التحقق من سبب التقييم السيئ والمقبول
  //       // تقييم المهندس
  //       if ((_userKpi[id] == bad || _userKpi[id] == well) &&
  //           (_kpiReasons[id] == null || _kpiReasons[id]!.text.isEmpty)) {
  //         _showAlertDialog('خطأ',
  //             'يرجى إدخال سبب التقييم (المقبول/السيئ) للمهندس في العنصر ${item['items']}.');
  //         return;
  //       }
  //       // تقييم مدير القطاع
  //       if ((_sectorKpi[id] == bad || _sectorKpi[id] == well) &&
  //           (_sectorKpiReasons[id] == null ||
  //               _sectorKpiReasons[id]!.text.isEmpty)) {
  //         _showAlertDialog('خطأ',
  //             'يرجى إدخال سبب التقييم (المقبول/السيئ) لمدير القطاع في العنصر ${item['items']}.');
  //         return;
  //       }
  //       // تقييم مدير المنطقة
  //       if ((_areaKpi[id] == bad || _areaKpi[id] == well) &&
  //           (_areaKpiReasons[id] == null ||
  //               _areaKpiReasons[id]!.text.isEmpty)) {
  //         _showAlertDialog('خطأ',
  //             'يرجى إدخال سبب التقييم (المقبول/السيئ) لمدير المنطقة في العنصر ${item['items']}.');
  //         return;
  //       }
  //       // تقييم اللجنة الفنية
  //       if ((_qualityKpi[id] == bad || _qualityKpi[id] == well) &&
  //           (_qualityKpiReasons[id] == null ||
  //               _qualityKpiReasons[id]!.text.isEmpty)) {
  //         _showAlertDialog('خطأ',
  //             'يرجى إدخال سبب التقييم (المقبول/السيئ) للجنة الفنية في العنصر ${item['items']}.');
  //         return;
  //       }
  //     }
  //   }
  //   // --- نهاية التعديل ---

  //   bool confirm = await _showConfirmationDialog();
  //   if (!confirm) return;

  //   try {
  //     for (var item in _items) {
  //       int id = item['id'];
  //       String? status = _itemStatuses[id];

  //       // if (item['is_saved'] == 0) { // ✅ تحديث فقط عندما is_saved = 0
  //       String? stats_time = status == 'under_progress'
  //           ? 'under_progress_time'
  //           : status == 'finished'
  //               ? 'finished_time'
  //               : status == 'cancel'
  //                   ? 'cancel_time'
  //                   : 'test_time';

  //       String? stats_user = status == 'under_progress'
  //           ? 'user_under_progress'
  //           : status == 'finished'
  //               ? 'user_finished'
  //               : status == 'cancel'
  //                   ? 'user_cancel'
  //                   : 'user_test';

  //       DateTime now = DateTime.now();

  //       await supabase
  //           .from('data_table')
  //           .update({
  //             'under_progress': status == 'under_progress',
  //             'finished': status == 'finished',
  //             'cancel': status == 'cancel',
  //             stats_time: now.toIso8601String(),
  //             stats_user: user_id,
  //             'cancel_reason':
  //                 status == 'cancel' ? _cancelReasons[id]!.text : null,
  //             'actual_qty': item['process_id'] == 5 && status == 'finished'
  //                 ? _processcontroller[id]!.text
  //                 : item['qty_balance'],
  //             'out_source': item['out_source'] ?? false, // ✅ أضف هذا السطر

  //             // 'is_saved': 1 // 🔥 بعد الحفظ يتم تحديث is_saved إلى 1
  //           })
  //           .eq('id', id)
  //           .eq('is_saved', 0); // ✅ تحديث الصف بناءً على ID
  //       // .eq('is_saved', 0); // ✅ ضمان تحديث الصفوف غير المحفوظة فقط
  //       // }
  //       if (user_respose['user_kpi_type'] == 1) {
  //         await supabase
  //             .from('data_table')
  //             .update({
  //               'user_kpi': _userKpi[id],
  //               'user_kpi_reason': _userKpi[id] == bad || _userKpi[id] == well
  //                   ? _kpiReasons[id]?.text
  //                   : null,
  //               'user_id_kpi': user_id,
  //             })
  //             .eq('id', id)
  //             .filter('user_kpi', 'is', null);
  //       }
  //       if (user_respose['user_kpi_type'] == 2) {
  //         await supabase
  //             .from('data_table')
  //             .update({
  //               'sector_kpi': _sectorKpi[id],
  //               'sector_kpi_reason':
  //                   _sectorKpi[id] == bad || _sectorKpi[id] == well
  //                       ? _sectorKpiReasons[id]?.text
  //                       : null,
  //               'sector_userid_kpi': user_id,
  //             })
  //             .eq('id', id)
  //             .filter('sector_kpi', 'is', null);
  //       }
  //       if (user_respose['user_kpi_type'] == 3) {
  //         await supabase
  //             .from('data_table')
  //             .update({
  //               'area_kpi': _areaKpi[id],
  //               'area_kpi_reason': _areaKpi[id] == bad || _areaKpi[id] == well
  //                   ? _areaKpiReasons[id]?.text
  //                   : null,
  //               'area_userid_kpi': user_id,
  //             })
  //             .eq('id', id)
  //             .filter('area_kpi', 'is', null);
  //       }
  //       if (user_respose['user_kpi_type'] == 4) {
  //         await supabase
  //             .from('data_table')
  //             .update({
  //               'quality_kpi': _qualityKpi[id],
  //               'quality_kpi_reason':
  //                   _qualityKpi[id] == bad || _qualityKpi[id] == well
  //                       ? _qualityKpiReasons[id]?.text
  //                       : null,
  //               'quality_userid_kpi': user_id,
  //             })
  //             .eq('id', id)
  //             .filter('quality_kpi', 'is', null);
  //       }
  //     }

  //     _showAlertDialog('نجاح', 'تم حفظ البيانات بنجاح!');
  //     setState(() {
  //       _fetchItems();
  //     });
  //   } catch (error) {
  //     print(error);
  //     _showAlertDialog('خطأ', 'حدث خطأ أثناء حفظ البيانات.');
  //   }
  // }
  Future<void> _saveData() async {
    if (!widget.checkdate) {
      _showAlertDialog('خطأ', 'لا يتم الحفظ الا علي تاريخ اليوم فقط.');
      return;
    }

    // التحقق من الشروط قبل الحفظ
    for (var item in _items) {
      int id = item['id'];
      String? status = _itemStatuses[id];

      if (status == 'cancel' && _cancelReasons[id]!.text.isEmpty) {
        _showAlertDialog(
            'خطأ', 'يجب إدخال سبب الإلغاء للعنصر ${item['items']}');
        return;
      }

      if (item['process_id'] == 5 &&
          _processcontroller[id]!.text.isEmpty &&
          status == 'finished') {
        _showAlertDialog('خطأ', 'يجب إدخال عدد ساعات الري الفعلية.');
        return;
      }

      if (status == 'finished') {
        if (user_respose['user_kpi_type'] == 1 && _userKpi[id] == null) {
          _showAlertDialog(
              'خطأ', 'يجب تسجيل تقييم المهندس أولاً للعنصر ${item['items']}');
          return;
        }

        if ((_userKpi[id] == bad || _userKpi[id] == well) &&
            (_kpiReasons[id] == null || _kpiReasons[id]!.text.isEmpty)) {
          _showAlertDialog('خطأ',
              'يرجى إدخال سبب التقييم (المقبول/السيئ) للمهندس في العنصر ${item['items']}');
          return;
        }

        if ((_sectorKpi[id] == bad || _sectorKpi[id] == well) &&
            (_sectorKpiReasons[id] == null ||
                _sectorKpiReasons[id]!.text.isEmpty)) {
          _showAlertDialog('خطأ',
              'يرجى إدخال سبب التقييم (المقبول/السيئ) لمدير القطاع في العنصر ${item['items']}');
          return;
        }

        if ((_areaKpi[id] == bad || _areaKpi[id] == well) &&
            (_areaKpiReasons[id] == null ||
                _areaKpiReasons[id]!.text.isEmpty)) {
          _showAlertDialog('خطأ',
              'يرجى إدخال سبب التقييم (المقبول/السيئ) لمدير المنطقة في العنصر ${item['items']}');
          return;
        }

        if ((_qualityKpi[id] == bad || _qualityKpi[id] == well) &&
            (_qualityKpiReasons[id] == null ||
                _qualityKpiReasons[id]!.text.isEmpty)) {
          _showAlertDialog('خطأ',
              'يرجى إدخال سبب التقييم (المقبول/السيئ) للجنة الفنية في العنصر ${item['items']}');
          return;
        }
      }
    }

    // تأكيد الحفظ
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    try {
      List<Future> updates = [];
      DateTime now = DateTime.now();

      for (var item in _items) {
        int id = item['id'];
        String? status = _itemStatuses[id];

        String? stats_time = status == 'under_progress'
            ? 'under_progress_time'
            : status == 'finished'
                ? 'finished_time'
                : status == 'cancel'
                    ? 'cancel_time'
                    : 'test_time';

        String? stats_user = status == 'under_progress'
            ? 'user_under_progress'
            : status == 'finished'
                ? 'user_finished'
                : status == 'cancel'
                    ? 'user_cancel'
                    : 'user_test';

        // تحديث رئيسي لكل عنصر
        updates.add(
          supabase
              .from('data_table')
              .update({
                'under_progress': status == 'under_progress',
                'finished': status == 'finished',
                'cancel': status == 'cancel',
                stats_time: now.toIso8601String(),
                stats_user: user_id,
                'cancel_reason':
                    status == 'cancel' ? _cancelReasons[id]?.text : null,
                'actual_qty': item['process_id'] == 5 && status == 'finished'
                    ? _processcontroller[id]!.text
                    : item['qty_balance'],
                'out_source': item['out_source'] ?? false,
              })
              .eq('id', id)
              .eq('is_saved', 0),
        );

        // تقييمات متعددة حسب نوع المستخدم
        if (user_respose['user_kpi_type'] == 1) {
          updates.add(
            supabase
                .from('data_table')
                .update({
                  'user_kpi': _userKpi[id],
                  'user_kpi_reason': _userKpi[id] == bad || _userKpi[id] == well
                      ? _kpiReasons[id]?.text
                      : null,
                  'user_id_kpi': user_id,
                })
                .eq('id', id)
                .filter('user_kpi', 'is', null),
          );
        } else if (user_respose['user_kpi_type'] == 2) {
          updates.add(
            supabase
                .from('data_table')
                .update({
                  'sector_kpi': _sectorKpi[id],
                  'sector_kpi_reason':
                      _sectorKpi[id] == bad || _sectorKpi[id] == well
                          ? _sectorKpiReasons[id]?.text
                          : null,
                  'sector_userid_kpi': user_id,
                })
                .eq('id', id)
                .filter('sector_kpi', 'is', null),
          );
        } else if (user_respose['user_kpi_type'] == 3) {
          updates.add(
            supabase
                .from('data_table')
                .update({
                  'area_kpi': _areaKpi[id],
                  'area_kpi_reason': _areaKpi[id] == bad || _areaKpi[id] == well
                      ? _areaKpiReasons[id]?.text
                      : null,
                  'area_userid_kpi': user_id,
                })
                .eq('id', id)
                .filter('area_kpi', 'is', null),
          );
        } else if (user_respose['user_kpi_type'] == 4) {
          updates.add(
            supabase
                .from('data_table')
                .update({
                  'quality_kpi': _qualityKpi[id],
                  'quality_kpi_reason':
                      _qualityKpi[id] == bad || _qualityKpi[id] == well
                          ? _qualityKpiReasons[id]?.text
                          : null,
                  'quality_userid_kpi': user_id,
                })
                .eq('id', id)
                .filter('quality_kpi', 'is', null),
          );
        }
      }

      // تنفيذ كل التحديثات مرة واحدة
      await Future.wait(updates);

      _showAlertDialog('نجاح', 'تم حفظ البيانات بنجاح!');
      setState(() {
        _fetchItems();
      });
    } catch (error) {
      print(error);
      _showAlertDialog('خطأ', 'حدث خطأ أثناء حفظ البيانات.');
    }
  }

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

  Future<bool?> _showDatePickerAndTransfer(Map<String, dynamic> item,
      {required bool fullTransfer}) async {
    DateTime selectedDate = DateTime.now();
    TextEditingController qtyController = TextEditingController();

    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            fullTransfer ? 'ترحيل العملية' : 'ترحيل جزء من العملية',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 500,
              ),
              Text('التاريخ', textAlign: TextAlign.center),
              SizedBox(
                height: 15,
              ),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: dialogContext, //استخدم سياق الـ dialog
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Text(
                  '${selectedDate.toLocal()}'.split(' ')[0],
                ),
              ),
              if (!fullTransfer)
                SizedBox(
                  height: 15,
                ),
              if (!fullTransfer)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          'أدخل الكمية المتبقية (متاح كمية ${item['qty_balance']} ${item['unit']}فقط)',
                    ),
                  ),
                ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () async {
                    double enteredQty =
                        double.tryParse(qtyController.text) ?? 0.0;
                    double qtyBalance = item['qty_balance'] ?? 0.0;

                    if (!fullTransfer && enteredQty > qtyBalance) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              'الكمية المدخلة لا يجب أن تتجاوز الرصيد المتبقي (${qtyBalance.toStringAsFixed(2)}).'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      print('بدأ الحفظ...');
                      _saveTransferData(
                        item,
                        selectedDate,
                        fullTransfer ? item['qty'] : enteredQty,
                        fullTransfer ? 'Full' : 'Part',
                      );
                      print('تم الحفظ');

                      // أغلق الديالوج بشكل آمن بعد الانتظار
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                        print('تم إغلاق الديالوج');
                      }
                    } catch (e) {
                      print("خطأ أثناء الحفظ: $e");
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
                      );
                    }
                  },
                  child: Text('موافق'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransferData(Map<String, dynamic> item, DateTime date,
      double qty, String post_type) async {
    await supabase.from('data_table').upsert({
      'date_from': date.toIso8601String(),
      'date_to': date.toIso8601String(),
      'process_id': item['process_id'],
      'items_id': item['items_id'],
      'qty': qty,
      'farm_id': item['farm_id'],
      'old_id': item['id'],
      'user_post': user_id,
      'post_type': post_type
    });
    await _fetchItems();
    _showAlertDialog('نجاح', 'تم الترحيل بنجاح');
  }

  Widget buildKpiSection({
    required int itemId,
    required String title,
    required Map<int, String?> kpiMap,
    required Map<int, TextEditingController> reasonMap,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: Icon(
                Icons.star,
                color: starNumber <= _getKpiStarCount(kpiMap[itemId])
                    ? Colors.amber
                    : Colors.grey[300],
              ),
              onPressed: () => onChanged(kpiLabels[starNumber]),
            );
          }),
        ),
        if (kpiMap[itemId] != null)
          Text(kpiMap[itemId]!,
              style: TextStyle(fontSize: 14, color: Colors.blue)),
        if (kpiMap[itemId] == bad || kpiMap[itemId] == well)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextField(
              controller: reasonMap[itemId],
              decoration: InputDecoration(
                labelText: kpiMap[itemId] == bad
                    ? 'سبب التقييم السيئ'
                    : 'سبب التقييم المقبول',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget buildKpiRowItem({
    required int itemId,
    required String title,
    required Map<int, String?> kpiMap,
    required Map<int, TextEditingController> reasonMap,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(
                  Icons.star,
                  size: 20,
                  color: starNumber <= _getKpiStarCount(kpiMap[itemId])
                      ? Colors.amber
                      : Colors.grey[300],
                ),
                onPressed: () => onChanged(kpiLabels[starNumber]),
              );
            }),
          ),
          if (kpiMap[itemId] != null)
            Text(kpiMap[itemId]!,
                style: TextStyle(fontSize: 10, color: Colors.blue)),
          if (kpiMap[itemId] == bad || kpiMap[itemId] == well)
            SizedBox(
              width: 100,
              child: TextField(
                controller: reasonMap[itemId],
                decoration: InputDecoration(
                  labelText: 'السبب',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 1,
                style: TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _isSaving, // يمنع أي تفاعل أثناء الحفظ
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: colorbar,
                foregroundColor: Colorapp,
                title: Text(
                    '${widget.processName} - ${widget.selectedDate.toLocal().toString().split(' ')[0]}'),
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
                ],
              ),
              body: _items.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: getFilteredItems().length,
                      itemBuilder: (context, index) {
                        final item = getFilteredItems()[index];
                        bool underProgressNotNull =
                            item['under_progress_time'] != null;
                        bool cancel_notnull = item['cancel_time'] != null;

                        return Card(
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        '${item['items']} : ${item['qty']} ${item['unit']}',
                                        style:
                                            TextStyle(color: MainFoantcolor)),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    if (item['is_out_source'] == 1 &&
                                        item['qty_balance'] > 0)
                                      Row(
                                        children: [
                                          Text(
                                            'عماله خارجية',
                                            style:
                                                TextStyle(color: color_under),
                                          ),
                                          Checkbox(
                                            value: item['out_source'] ?? false,
                                            onChanged:
                                                _itemStatuses[item['id']] ==
                                                        'finished'
                                                    ? null
                                                    : (val) {
                                                        setState(() {
                                                          item['out_source'] =
                                                              val!;
                                                        });
                                                      },
                                          ),
                                        ],
                                      ),
                                    if (item['process_id'] == 5 &&
                                        _itemStatuses[item['id']] ==
                                            'finished' &&
                                        item['qty_balance'] > 0)
                                      SizedBox(
                                        width: 150,
                                        child: TextField(
                                          controller:
                                              _processcontroller[item['id']],
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d{0,}$')),
                                          ],
                                          decoration: InputDecoration(
                                            labelText: 'كمية الري الفعلية',
                                          ),
                                        ),
                                      ),
                                    if (item['qty_balance'] == 0 &&
                                        item['qty'] > 0)
                                      Text(
                                        'العملية مُرحله',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    if (item['qty_balance'] < item['qty'] &&
                                        item['qty_balance'] > 0)
                                      Text(
                                        'باقي كمية :${item['qty_balance']}',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(item['shoet_farm_code'],
                                        style: TextStyle(
                                            color: Colors.blue, fontSize: 12)),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: MainFoantcolor,
                                      ),
                                      onSelected: (value) async {
                                        bool? result;

                                        if (value == 'full_transfer') {
                                          result =
                                              await _showDatePickerAndTransfer(
                                                  item,
                                                  fullTransfer: true);
                                        } else if (value ==
                                            'partial_transfer') {
                                          result =
                                              await _showDatePickerAndTransfer(
                                                  item,
                                                  fullTransfer: false);
                                          print('result::$result');
                                        }

                                        if (result == true) {
                                          // await _fetchItems();

                                          setState(() {});
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (user_respose['can_post'] == 1 &&
                                            _itemStatuses[item['id']] == null &&
                                            item['qty_balance'] == item['qty'])
                                          PopupMenuItem(
                                            value: 'full_transfer',
                                            child: Text('ترحيل العملية'),
                                          ),
                                        if (user_respose['can_post'] == 1 &&
                                            item['qty_balance'] > 0 &&
                                            (_itemStatuses[item['id']] ==
                                                    null ||
                                                _itemStatuses[item['id']] ==
                                                    'under_progress'))
                                          PopupMenuItem(
                                            value: 'partial_transfer',
                                            child: Text('ترحيل جزء من العملية'),
                                          ),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                            subtitle: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'قيد التنفيذ',
                                          style: TextStyle(color: color_under),
                                        ),
                                        Radio<String>(
                                          value: 'under_progress',
                                          activeColor: color_under,
                                          groupValue: _itemStatuses[item['id']],
                                          onChanged: user_type != 2 ||
                                                  item['qty_balance'] == 0
                                              ? null
                                              : underProgressNotNull
                                                  ? null
                                                  : cancel_notnull
                                                      ? null
                                                      : (value) => setState(
                                                          () => _itemStatuses[
                                                                  item['id']] =
                                                              value),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text('منتهي',
                                            style:
                                                TextStyle(color: color_finish)),
                                        Radio<String>(
                                          value: 'finished',
                                          activeColor: color_finish,
                                          groupValue: _itemStatuses[item['id']],
                                          onChanged: user_type != 2 ||
                                                  item['qty_balance'] == 0
                                              ? null
                                              : cancel_notnull
                                                  ? null
                                                  : underProgressNotNull
                                                      ? (value) => setState(
                                                          () => _itemStatuses[
                                                                  item['id']] =
                                                              value)
                                                      : null,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text('ملغي',
                                            style:
                                                TextStyle(color: color_cancel)),
                                        Radio<String>(
                                          value: 'cancel',
                                          activeColor: color_cancel,
                                          groupValue: _itemStatuses[item['id']],
                                          onChanged: user_type != 2 ||
                                                  item['qty_balance'] == 0
                                              ? null
                                              : underProgressNotNull
                                                  ? null
                                                  : (value) => setState(() =>
                                                      _itemStatuses[
                                                          item['id']] = value),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_itemStatuses[item['id']] == 'cancel')
                                  TextField(
                                    controller: _cancelReasons[item['id']],
                                    decoration: InputDecoration(
                                        labelText: 'سبب الإلغاء'),
                                  ),
                                if (_itemStatuses[item['id']] ==
                                    'finished') ...[
                                  Row(
                                    children: [
                                      if (user_respose['user_kpi_type'] == 1 ||
                                          _userKpi[item['id']] != null)
                                        Expanded(
                                          child: buildKpiSection(
                                            itemId: item['id'],
                                            title: 'تقييم المهندس',
                                            kpiMap: _userKpi,
                                            reasonMap: _kpiReasons,
                                            onChanged: (val) => setState(() =>
                                                _userKpi[item['id']] = val),
                                          ),
                                        ),
                                      SizedBox(width: 8),
                                      if (user_respose['user_kpi_type'] == 2 ||
                                          _sectorKpi[item['id']] != null)
                                        Expanded(
                                          child: buildKpiSection(
                                            itemId: item['id'],
                                            title: 'تقييم مدير القطاع',
                                            kpiMap: _sectorKpi,
                                            reasonMap: _sectorKpiReasons,
                                            onChanged: (val) => setState(() =>
                                                _sectorKpi[item['id']] = val),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (user_respose['user_kpi_type'] == 3 ||
                                          _areaKpi[item['id']] != null)
                                        Expanded(
                                          child: buildKpiSection(
                                            itemId: item['id'],
                                            title: 'تقييم مدير المنطقة',
                                            kpiMap: _areaKpi,
                                            reasonMap: _areaKpiReasons,
                                            onChanged: (val) => setState(() =>
                                                _areaKpi[item['id']] = val),
                                          ),
                                        ),
                                      SizedBox(width: 8),
                                      if (user_respose['user_kpi_type'] == 4 ||
                                          _qualityKpi[item['id']] != null)
                                        Expanded(
                                          child: buildKpiSection(
                                            itemId: item['id'],
                                            title: 'تقييم اللجنة الفنية',
                                            kpiMap: _qualityKpi,
                                            reasonMap: _qualityKpiReasons,
                                            onChanged: (val) => setState(() =>
                                                _qualityKpi[item['id']] = val),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              floatingActionButton: user_type == 2
                  ? FloatingActionButton(
                      onPressed: () async {
                        setState(() => _isSaving = true);
                        await _saveData(); // الدالة مش بترجع حاجة
                        setState(() => _isSaving = false);
                      },
                      child: Icon(Icons.save),
                    )

                  // FloatingActionButton(
                  //     onPressed: _saveData,
                  //     child: Icon(Icons.save),
                  //   )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
