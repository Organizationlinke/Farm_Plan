import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;

class SolutionsFormScreen extends StatefulWidget {
  final int farmId;
  final int processId;
  final int problemsId;
  final String farmText;
  final String processText;

  const SolutionsFormScreen({
    required this.farmId,
    required this.processId,
    required this.problemsId,
    required this.farmText,
    required this.processText,
    super.key,
  });

  @override
  State<SolutionsFormScreen> createState() => _ProblemFormScreenState();
}

class _ProblemFormScreenState extends State<SolutionsFormScreen> {
  DateTime? selectedDate;
  TextEditingController noteController = TextEditingController();
  List<Map<String, dynamic>> itemRows = [];
  int refuse = 0;
  List<Map<String, dynamic>> itemsList = [];
  int statuse = 0;
  TextEditingController refuseController = TextEditingController();
  int? is_refuse ;
  @override
  void initState() {
    super.initState();
    fetchItems();
    if (widget.problemsId != 0) {
      fetchExistingData();
    }
    fetchRefuse();
  }

  Future<void> saveRefuse() async {
    try {
      await Supabase.instance.client.from('proplems').update({
        'is_solution_refuse': 1,
        'refuse_solution_reason': refuseController.text,
      }).eq('id', widget.problemsId);
    } catch (e) {}
  }

  Future<void> fetchRefuse() async {
    final response = await Supabase.instance.client
        .from('proplems')
        .select()
        .eq('id', widget.problemsId)
        .eq('is_solution_refuse', 1);
    if (response.isNotEmpty) {
      final data = response.first;
      refuseController.text = data['refuse_solution_reason'] ?? '';
      is_refuse = 1;
    } else {
      is_refuse = 0;
    }
  }

  Future<void> fetchItems() async {
    final response = await Supabase.instance.client
        .from('items_view')
        .select('id, items, unit')
        .eq('process_id', widget.processId);
    setState(() {
      itemsList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> fetchExistingData() async {
    final response = await Supabase.instance.client
        .from('data_table_full_view')
        .select()
        .eq('proplems_id', widget.problemsId);

    if (response.isNotEmpty) {
      final data = response.first;
      if (data['date_from'] != null) {
        selectedDate = DateTime.tryParse(data['date_from']);
      }

      // selectedDate = DateTime.parse(data['date_from']);
      noteController.text = data['note'] ?? '';
      statuse = data['proplems_status'] ?? 0;
      itemRows = response
          .map<Map<String, dynamic>>((row) => {
                'item': {
                  'id': row['items_id'],
                  'items': row['items'],
                  'unit': row['unit'],
                },
                'qty': row['qty'],
              })
          .toList();
      setState(() {});
    }
  }

  void addItemRow() {
    setState(() {
      itemRows.add({'item': null, 'qty': ''});
    });
  }

  void removeItemRow(int index) {
    setState(() {
      itemRows.removeAt(index);
    });
  }

  Future<void> AcceptSolution() async {
    try {
      final result = await Supabase.instance.client
          .from('data_table')
          .update({'proplems_status': 2})
          .eq('proplems_id', widget.problemsId)
          .select(); // علشان ترجّع البيانات بعد التعديل
      await fetchExistingData();
      setState(() {});
    } catch (e) {
      print('Error while updating problem status: $e');
    }
  }

  Future<void> saveData() async {
    // تحقق من التكرار في الأصناف الحالية قبل الحفظ
    final selectedIds =
        itemRows.map((row) => row['item']?['id']).whereType<int>().toList();

    final hasDuplicates = selectedIds.length != selectedIds.toSet().length;

    if (hasDuplicates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يوجد أصناف مكررة، يرجى إزالة التكرار قبل الحفظ')),
      );
      return; // يمنع الاستمرار في الحفظ
    }

    // ... باقي كود الحفظ اللي كتبته من قبل
    final existingRows = await Supabase.instance.client
        .from('data_table')
        .select('id, items_id')
        .eq('proplems_id', widget.problemsId)
        .eq('isdelete', 0);

    final Map<int, int> existingItemsMap = {
      for (var row in existingRows) row['items_id'] as int: row['id'] as int,
    };

    final Set<int> currentItemIds = {};

    for (var row in itemRows) {
      final item = row['item'];
      final qty = row['qty'];

      if (item == null || qty == null || qty.toString().isEmpty) continue;

      final int itemId = item['id'] as int;

      final data = {
        'farm_id': widget.farmId,
        'process_id': widget.processId,
        'proplems_id': widget.problemsId,
        'date_from': selectedDate?.toIso8601String(),
        'date_to': selectedDate?.toIso8601String(),
        'items_id': itemId,
        'qty': qty,
        'note': noteController.text,
        'proplems_status': 1,
        'isdelete': 0,
      };

      currentItemIds.add(itemId);

      if (existingItemsMap.containsKey(itemId)) {
        final existingId = existingItemsMap[itemId]!;
        await Supabase.instance.client
            .from('data_table')
            .update(data)
            .eq('id', existingId);
      } else {
        await Supabase.instance.client.from('data_table').insert(data);
      }
    }

    for (var itemId in existingItemsMap.keys) {
      if (!currentItemIds.contains(itemId)) {
        final idToDelete = existingItemsMap[itemId]!;
        await Supabase.instance.client
            .from('data_table')
            .update({'isdelete': 1}).eq('id', idToDelete);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل العملية'),
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: ListView(
            children: [
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'رقم الطلبية: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: MainFoantcolor,
                      fontSize: 20,
                    ),
                    children: [
                      TextSpan(
                        text: widget.problemsId.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    "المنطقة: ",
                    style: TextStyle(color: Colors.blue, fontSize: 18),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Text(
                    widget.farmText,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  Text(
                    "العملية المطلوبة: ",
                    style: TextStyle(color: Colors.blue, fontSize: 18),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Text(
                    widget.processText,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "------------------------------------------",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text(
                    'تاريخ العملية',
                    style: TextStyle(color: Colors.blue),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Text(selectedDate != null
                      ? dateFormatter.format(selectedDate!)
                      : 'اختر التاريخ'),
                  SizedBox(
                    width: 15,
                  ),
                  IconButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                      icon: const Icon(Icons.date_range, color: Colors.blue))
                ],
              ),
              const SizedBox(height: 15),
              const Text('تفاصيل الأصناف:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: MainFoantcolor,
                      fontSize: 18)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemRows.length,
                itemBuilder: (context, index) {
                  final row = itemRows[index];
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          hint: const Text('اختر الصنف'),
                          value: row['item']?['id'],
                          isExpanded: true,
                          items: itemsList.map((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['items']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final selectedItem = itemsList.firstWhere(
                                (element) => element['id'] == value);
                            setState(() {
                              row['item'] = selectedItem;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'الكمية'),
                          keyboardType: TextInputType.number,
                          initialValue: row['qty']?.toString() ?? '',
                          onChanged: (val) => row['qty'] = val,
                        ),
                      ),
                      IconButton(
                        onPressed: () => removeItemRow(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Card(
                child: SizedBox(
                    width: 150,
                    child: TextButton(
                      onPressed: addItemRow,
                      child: Text('إضافة صنف'),
                    )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  // labelStyle: TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              if (user_respose['can_solution'] == 1 &&
                  statuse < 2 &&
                  is_refuse == 0)
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  onPressed: saveData,
                ),
              // if (is_refuse != 1 ||statuse!=2)
              if (user_respose['accept_solution'] == 1 &&
                  statuse < 2 &&
                   is_refuse == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('موافقه علي الحل'),
                      onPressed: AcceptSolution,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('رفض الحل'),
                      onPressed: () {
                        setState(() {
                          refuse = 1;
                        });
                      },
                    ),
                  ],
                ),

              if (user_respose['accept_solution'] == 1 && refuse == 1)
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  if (statuse == 2)
                    Text('الحالة : تم الموافقه علي الحل',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MainFoantcolor,
                            fontSize: 20)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
