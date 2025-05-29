import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  List<Map<String, dynamic>> processes = [];
  final TextEditingController _controller = TextEditingController();
  int? editingId;

  @override
  void initState() {
    super.initState();
    loadProcesses();
  }

  Future<void> loadProcesses() async {
    // جلب البيانات من Supabase أو أي مصدر آخر
    final response =
        await Supabase.instance.client.from('process').select().order('id');
    setState(() => processes = List<Map<String, dynamic>>.from(response));
  }

  Future<void> saveProcess() async {
    final name = _controller.text;
    if (editingId == null) {
      await Supabase.instance.client
          .from('process')
          .insert({'process_name': name});
    } else {
      await Supabase.instance.client
          .from('process')
          .update({'process_name': name}).eq('id', editingId!);
    }
    _controller.clear();
    editingId = null;
    await loadProcesses();
  }

  Future<void> deleteProcess(int id) async {
    await Supabase.instance.client.from('process').delete().eq('id', id);
    await loadProcesses();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تعريف العمليات"),
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
        ),
        body: Column(
          children: [
            TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'اسم العملية')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 1, 131, 5),
                    foregroundColor: Colors.white),
                onPressed: saveProcess,
                child: const Text("حفظ")),
            Expanded(
              child: ListView.builder(
                itemCount: processes.length,
                itemBuilder: (context, index) {
                  final p = processes[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        p['process_name'],
                        style: TextStyle(color: MainFoantcolor, fontSize: 18),
                      ),
                      subtitle: Text('ID: ${p['id']}',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                                _controller.text = p['process_name'];
                                editingId = p['id'];
                              }
                            },
                            // onPressed: () {
                            //   _controller.text = p['process_name'];
                            //   editingId = p['id'];
                            // }
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            // onPressed: () => deleteProcess(p['id'])
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
                                deleteProcess(p['id']);
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
