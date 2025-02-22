import 'package:farmplanning/Sub_process.dart';
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainProcessScreen extends StatefulWidget {
  const MainProcessScreen({super.key});

  @override
  State<MainProcessScreen> createState() => _MainProcessScreenState();
}

class _MainProcessScreenState extends State<MainProcessScreen> {
  DateTime selectedDate = DateTime.now();
  final supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> areas =
      []; // نتائج الاستعلام من قاعدة البيانات
  final List<Map<String, dynamic>> selectedAreas =
      []; // العناصر اللي هيتم عرضها في row2

  @override
  void initState() {
    super.initState();
    fetchAreas();
    checked();
  }

  Future<List<Map<String, dynamic>>> fetchGroupedProcesses() async {
    final response = await supabase
        .from('data_table_full_view2')
        .select()
        .like('farm_code', '$New_user_area%')
        .gte('date_to', selectedDate.toIso8601String())
        .lte('date_from', selectedDate.toIso8601String());

    final data = response as List;
    final grouped = <String, Map<String, dynamic>>{};

    for (var item in data) {
      grouped[item['process_name']] = item;
    }

    return grouped.values.toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> fetchAreas() async {
    final result = await supabase
        .from('farm')
        .select()
        .like('farm_code', '$New_user_area%')
        .eq('level', new_level);

    if (result.isNotEmpty) {
      areas.clear();
      setState(() {
        areas.addAll(result.map((e) => e).toList());
      });
    }
  }

  void selectArea(Map<String, dynamic> area) async {
    if (!selectedAreas.contains(area)) {
      Old_user_area=New_user_area;
      New_user_area = area['farm_code'];
      new_level++;
      print(New_user_area);
      checked();
      await fetchAreas();

      setState(() {
        selectedAreas.add(area);
      });
    }
  }

  void removeArea(Map<String, dynamic> area) async{
    
      New_user_area = Old_user_area;
    new_level--;
    checked();
      await fetchAreas();
    setState(() {
      selectedAreas.remove(area);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          // leading: Text(farm_title),
          // toolbarHeight: 1,
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Text(
                      ' ${selectedDate.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  Row(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: selectedAreas.map((area) {
                            return Container(
                              // margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 228, 230, 228),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    area[old_check_farm].toString(),
                                    style: const TextStyle(
                                         fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => removeArea(area),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.red,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Text(user_area),
                    ],
                  )
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: areas.map((area) {
                    return GestureDetector(
                      onTap: () {
                        selectArea(area);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          area[check_farm].toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        body: FutureBuilder(
          future: fetchGroupedProcesses(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final processes = snapshot.data as List<Map<String, dynamic>>;

            return ListView.builder(
              itemCount: processes.length,
              itemBuilder: (context, index) {
                final process = processes[index];

                return ListTile(
                  title: Text(process['process_name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubProcessScreen(
                          selectedDate: selectedDate,
                          processName: process['process_name'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
