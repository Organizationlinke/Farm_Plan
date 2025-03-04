import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
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
        _cancelReasons[item['id']] = TextEditingController();
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

        // DateTime now = DateTime.now();

        await supabase
            .from('data_table')
            .update({
              'under_progress': status == 'under_progress',
              'finished': status == 'finished',
              'cancel': status == 'cancel',
              stats_time: currentDate,
              'cancel_reason':
                  status == 'cancel' ? _cancelReasons[item['id']]!.text : null,
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

 
  void _showDatePickerAndTransfer(Map<String, dynamic> item,
      {required bool fullTransfer}) {
    DateTime selectedDate = DateTime.now();
    TextEditingController qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            fullTransfer ? 'ترحيل العملية' : 'ترحيل جزء من العملية',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('التاريخ', textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Text(
                  '${selectedDate.toLocal()}'.split(' ')[0],
                  textAlign: TextAlign.center,
                ),
              ),
              if (!fullTransfer)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'أدخل الكمية المتبقية',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', textAlign: TextAlign.right),
                ),
                TextButton(
                  onPressed: () {
                    _saveTransferData(
                      item,
                      selectedDate,
                      fullTransfer
                          ? item['qty']
                          : double.tryParse(qtyController.text) ?? 0.0,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('موافق', textAlign: TextAlign.left),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransferData(
      Map<String, dynamic> item, DateTime date, double qty) async {
    await supabase.from('data_table').upsert({
      'date_from': date.toIso8601String(),
      'date_to': date.toIso8601String(),
      'process_id': item['process_id'],
      'items_id': item['items_id'],
      'qty': qty,
      'farm_id': item['farm_id'],
      'old_id': item['id'],
    });
    _showAlertDialog('نجاح', 'تمت الترحيل بنجاح');
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
                          Text(
                              '${item['items']} : ${item['qty']} ${item['unit']}',
                              style: TextStyle(color: Colorapp)),

                          Row(
                            children: [
                               Text(
                              item['shoet_farm_code'],
                              style: TextStyle(color: Colors.blue,fontSize: 12)),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colorapp,
                                ),
                                onSelected: (value) {
                                  if (value == 'full_transfer') {
                                    _showDatePickerAndTransfer(item,
                                        fullTransfer: true);
                                  } else if (value == 'partial_transfer') {
                                    _showDatePickerAndTransfer(item,
                                        fullTransfer: false);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'full_transfer',
                                    child: Text('ترحيل العملية'),
                                  ),
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
                                    onChanged: user_type != 2
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
                                    onChanged: user_type != 2
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
                                    onChanged: user_type != 2
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
