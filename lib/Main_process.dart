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
  // final List<Map<String, dynamic>> selectedAreas =
  //     []; // العناصر اللي هيتم عرضها في row2

  final List<String> selectedAreas = []; // الآن القائمة تحتوي على نصوص فقط

  @override
  void initState() {
    super.initState();
    fetchAreas();
    checked();
    // fetchGroupedProcesses();
  }

  Future<List<Map<String, dynamic>>> fetchGroupedProcesses() async {
    final response = await supabase.rpc('fetch_process_data', params: {
      'farm_code_param': '$New_user_area%',
      'date_from_param': selectedDate.toIso8601String(),
      'date_to_param': selectedDate.toIso8601String(),
    });

    // التحقق مما إذا كان `response` يحتوي على خطأ
    if (response is Map<String, dynamic> && response.containsKey('error')) {
      throw Exception('خطأ في جلب البيانات: ${response['error']}');
    }

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }

    throw Exception('تنسيق غير متوقع للبيانات: $response');
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
    areas.clear();
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
    String areaCode = area['farm_code']; // استخراج النص من الخريطة
    print('areaCode:$areaCode');
    if (!selectedAreas.contains(areaCode)) {
      // Old_user_area = New_user_area;
      // Old_user_area_IN();
      New_user_area = areaCode;
      print('New_user_area:$New_user_area');
      String areaCode2 = area[check_farm];

      new_level++;

      checked();

      await fetchAreas();

      setState(() {
        selectedAreas.add(areaCode2); // إضافة النص بدلاً من الخريطة
      });
    }
  }


  void removeArea(String areaCode) async {
    //
    // Old_user_area_OUT();
    New_user_area = New_user_area.replaceAll('-$areaCode', "");
    new_level--;
    print(New_user_area);
    checked();
    await fetchAreas();
    setState(() {
      selectedAreas.remove(areaCode); // حذف العنصر النصي
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
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
                   
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: selectedAreas.map((areaCode) {
                            bool isLast = selectedAreas.last ==
                                areaCode; // التحقق من آخر عنصر
                        
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 228, 230, 228),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    areaCode,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isLast) // إظهار أيقونة الإغلاق فقط للعنصر الأخير
                                    GestureDetector(
                                      onTap: () => removeArea(areaCode),
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
            ],
          ),
        ),
        body: Row(
          children: [
            Container(
              color: const Color.fromARGB(255, 235, 235, 235),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: areas.map((area) {
                  return GestureDetector(
                    onTap: () {
                      selectArea(area);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:Colorapp,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        area[check_farm].toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder(
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

                      return Card(
                        child: ListTile(
                          title: Text(
                            '${process['group_process_name']} : ${process['allprocess']} عملية ',
                            style: TextStyle(fontSize: 20, color:Colorapp),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('انتظار: ${process['waited']}'),
                              Text('تحت التشغيل: ${process['under_progress']}',style: TextStyle( color:const Color.fromARGB(255, 192, 144, 0))),
                              Text('منتهي:${process['finished']} ',style: TextStyle( color:Colors.green)),
                              Text('ملغي: ${process['cancel']}',style: TextStyle( color:Colors.red))
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DataTableScreen(
                                  selectedDate: selectedDate,
                                  processName: process['group_process_name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
