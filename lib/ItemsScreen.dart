
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> processes = [];

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  int? selectedProcessId;
  int? editingId;

  @override
  void initState() {
    super.initState();
    loadProcesses();
    loadItems();
  }

  Future<void> loadProcesses() async {
    final response = await Supabase.instance.client.from('process').select().eq('isdelete', 0);
    setState(() => processes = List<Map<String, dynamic>>.from(response));
  }

  Future<void> loadItems() async {
    final response = await Supabase.instance.client.from('items_view').select();
    setState(() => items = List<Map<String, dynamic>>.from(response));
  }

  Future<void> saveItem() async {
    final name = itemNameController.text;
    final unit = unitController.text;
    print('selectedProcessId:$selectedProcessId');
    if (selectedProcessId == null || name.isEmpty || unit.isEmpty) return;

    final data = {
      'items': name,
      'unit': unit,
      'process_id': selectedProcessId,
    };

    if (editingId == null) {
      await Supabase.instance.client.from('items').insert(data);
    } else {
      await Supabase.instance.client
          .from('items')
          .update(data)
          .eq('id', editingId!);
    }

    itemNameController.clear();
    unitController.clear();
    selectedProcessId = null;
    editingId = null;
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await Supabase.instance.client
          .from('items')
          .update({'isdelete': 1})
          .eq('id', id);
    // await Supabase.instance.client.from('items').delete().eq('id', id);
    await loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تعريف الأصناف"),
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
        ),
        body: Column(
          children: [
            TextField(
              controller: itemNameController,
              decoration: const InputDecoration(labelText: 'اسم الصنف'),
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'الوحدة'),
            ),
            DropdownButton<int>(
              value: selectedProcessId,
              hint: const Text("اختر العملية"),
              isExpanded: true,
              items: processes.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(
                  value: p['id'] as int,
                  child: Text(p['process_name']),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedProcessId = val),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 1, 131, 5),
                    foregroundColor: Colors.white),
                onPressed: saveItem,
                child: const Text("حفظ")),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${item['items']} (${item['unit']})',
                        style: TextStyle(color: MainFoantcolor, fontSize: 18),
                      ),
                      subtitle: Text(' ID: ${item['id']}',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      // Text('عملية: ${item['process_name']} - ID: ${item['id']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.green,
                              ),
                                    onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('تأكيد التعديل'),
                                  content: const Text(
                                      'هل أنت متأكد أنك تريد تعديل هذا الصنف؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('تعديل'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                              
                                itemNameController.text = item['items'];
                                unitController.text = item['unit'];
                                selectedProcessId = item['process_id'];
                                editingId = item['id'];
                                setState(() {});
                              
                              }
                            },
                              // onPressed: () {
                              //   itemNameController.text = item['items'];
                              //   unitController.text = item['unit'];
                              //   selectedProcessId = item['process_id'];
                              //   editingId = item['id'];
                              //   setState(() {});
                              // }
                              
                              
                              
                              ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            // onPressed: () => deleteItem(item['id'])
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: const Text(
                                      'هل أنت متأكد أنك تريد حذف هذا الصنف؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                deleteItem(item['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
