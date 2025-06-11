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

  final _cancel_reason = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchItems();
    getCurrentDateFromSupabase();
  }

  Future<DateTime?> getCurrentDateFromSupabase() async {
    try {
      final response = await supabase
          .rpc('get_server_time'); // استدعاء دالة SQL نصنعها يدويًا
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
        _itemStatuses[item['id']] = item['finished'] == true
            ? 'finished'
            : item['under_progress'] == true
                ? 'under_progress'
                : item['cancel'] == true
                    ? 'cancel'
                    : null;

        _cancelReasons[item['id']] =
            TextEditingController(text: item['cancel_reason'] ?? '');
        _processcontroller[item['id']] = TextEditingController(
            text: item['actual_qty'].toString() == 'null'
                ? ''
                : item['actual_qty'].toString());
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

  Future<void> _saveData() async {
    if (!widget.checkdate) {
      _showAlertDialog('خطأ', 'لا يتم الحفظ الا علي تاريخ اليوم فقط.');
      return;
    }
    for (var item in _items) {
      if (_itemStatuses[item['id']] == 'cancel' &&
          _cancelReasons[item['id']]!.text.isEmpty) {
        _showAlertDialog('خطأ', 'يجب إدخال سبب الإلغاء.');
        return;
      }
      if (item['process_id'] == 5 &&
          _processcontroller[item['id']]!.text.isEmpty &&
          _itemStatuses[item['id']] == 'finished') {
        _showAlertDialog('خطأ', 'يجب إدخال عدد ساعات الري الفعليه.');
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

        String? stats_user = status == 'under_progress'
            ? 'user_under_progress'
            : status == 'finished'
                ? 'user_finished'
                : status == 'cancel'
                    ? 'user_cancel'
                    : 'user_test';

        DateTime now = DateTime.now();

        await supabase
            .from('data_table')
            .update({
              'under_progress': status == 'under_progress',
              'finished': status == 'finished',
              'cancel': status == 'cancel',
              stats_time: now.toIso8601String(),
              stats_user: user_id,
              'cancel_reason':
                  status == 'cancel' ? _cancelReasons[item['id']]!.text : null,
              'actual_qty': item['process_id'] == 5 &&
                      _itemStatuses[item['id']] == 'finished'
                  ? _processcontroller[item['id']]!.text
                  : item['qty_balance'],
              'out_source': item['out_source'] ?? false, // ✅ أضف هذا السطر
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
            SizedBox(width: 500,),
            Text('التاريخ', textAlign: TextAlign.center),
            SizedBox(height: 15,),
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: dialogContext, // استخدم سياق الـ dialog
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
             SizedBox(height: 15,),
            if (!fullTransfer)
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'أدخل الكمية المتبقية (متاح كمية ${item['qty_balance']} ${item['unit']} فقط)',
                  ),

                ),
              ),
               SizedBox(height: 15,),
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
    _showAlertDialog('نجاح', 'تم الترحيل بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
                // itemCount: _items.length,
                itemCount: getFilteredItems().length,
                itemBuilder: (context, index) {
                  // final item = _items[index];
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
                                  style: TextStyle(color: MainFoantcolor)),
                              SizedBox(
                                width: 15,
                              ),
                              if (item['is_out_source'] == 1 &&
                                  item['qty_balance'] > 0)
                                Row(
                                  children: [
                                    Text(
                                      'عماله خارجية',
                                      style: TextStyle(color: color_under),
                                    ),
                                    Checkbox(
                                      value: item['out_source'] ?? false,
                                      onChanged:_itemStatuses[item['id']] == 'finished'?null: (val) {
                                        setState(() {
                                          item['out_source'] = val!;
                                        
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              if (item['process_id'] == 5 &&
                                  _itemStatuses[item['id']] == 'finished' &&
                                  item['qty_balance'] > 0)
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _processcontroller[item['id']],
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
                              if (item['qty_balance'] == 0)
                                Text(
                                  'العملية مُرحله',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                  if (item['qty_balance'] < item['qty'])
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
                                    result = await _showDatePickerAndTransfer(
                                        item,
                                        fullTransfer: true);
                                  } else if (value == 'partial_transfer') {
                                    result = await _showDatePickerAndTransfer(
                                        item,
                                        fullTransfer: false);
                                        print('result::$result');
                                  }

                                  if (result == true) {
                                    await _fetchItems();
                                     
                                    setState(() {});
                                  }
                                },

                                //&&_itemStatuses[item['id']]!='cancel'&&_itemStatuses[item['id']]!='finished'
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
                                      (_itemStatuses[item['id']] == null ||
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                : (value) => setState(() =>
                                                    _itemStatuses[item['id']] =
                                                        value),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('منتهي',
                                      style: TextStyle(color: color_finish)),
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
                                                ? (value) => setState(() =>
                                                    _itemStatuses[item['id']] =
                                                        value)
                                                : null,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('ملغي',
                                      style: TextStyle(color: color_cancel)),
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
                                                _itemStatuses[item['id']] =
                                                    value),
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
        floatingActionButton: user_type == 2
            ? FloatingActionButton(
                onPressed: _saveData,
                child: Icon(Icons.save),
              )
            : null,
      ),
    );
  }
}
