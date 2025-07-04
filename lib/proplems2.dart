
// استورد الحزم المطلوبة
import 'package:farmplanning/RequestDetailPage.dart';
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// الشاشة الأولى: قائمة الطلبات
class RequestListPage2 extends StatefulWidget {
  @override
  _RequestListPageState createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage2> {
  List<dynamic> requests = [];
  final List<Map<String, dynamic>> areas = [];
  // final List<String> selectedAreas = [];
  bool _isUpdating = false;


  @override
  void initState() {
    super.initState();
    fetchRequests();
    fetchAreas();
    checked2();
  }

  Future<void> fetchAreas() async {
    areas.clear();
    final result = await Supabase.instance.client
        .from('farm_users')
        .select()
        .like('farm_code', '$New_user_area2%')
        .eq('level', new_level2)
         .eq('user_id', user_id);
         
       

    if (result.isNotEmpty) {
      setState(() {
        areas.clear();
        areas.addAll(result.map((e) => e).toList());
      });
    }
  }

  void selectArea(Map<String, dynamic> area) async {
    if (_isUpdating) return;
    _isUpdating = true;

    String areaCode = area['farm_code'];
    String areaCode2 = area[check_farm2];

    if (!selectedAreas2.contains(areaCode2)) {
      New_user_area2 = areaCode;
      new_level2++;
      checked2();
      await fetchAreas();
      await fetchRequests();
      setState(() {
        selectedAreas2.add(areaCode2);
      });
    }
    _isUpdating = false;
  }

  void removeArea(String areaCode) async {
    if (_isUpdating) return;
    _isUpdating = true;

    New_user_area2 = New_user_area2.replaceAll('-$areaCode', "");
    new_level2--;
    checked2();
    await fetchAreas();
    await fetchRequests();
    setState(() {
      selectedAreas2.remove(areaCode);
    });
    _isUpdating = false;
  }

  Future<void> fetchRequests() async {
    print(New_user_area2);
    final response = await Supabase.instance.client
        .from('proplems_view')
        .select()
        .eq('user_id_area', user_id)
        .like('farm_code', '$New_user_area2%');
    if (!mounted) return;
    setState(() {
      requests = response;
    });
  }
Widget buildRequestList({required String filter, required int is_finish}) {
  List<dynamic> filteredRequests;

  if (filter == 'new') {
    filteredRequests = requests
        .where((item) =>
            item['proplems_status'] == 0 )//&& item['is_refuse'] == 0
        .toList();
  } else if (filter == 'solved') {
    filteredRequests =
        requests.where((item) => item['proplems_status'] == 1).toList();//&&item['is_solution_refuse'] == 0
  } else if (filter == 'pending') {
    filteredRequests = requests
        .where((item) =>
        item['proplems_status'] ==2)
            // item['is_finished'] == 0 &&
            // (item['proplems_status'] == 2 ||
            //     item['is_solution_refuse'] == 1 ||
            //     item['is_refuse'] == 1))
        .toList();
  } else {
    filteredRequests = requests;
  }

  return ListView.builder(
    itemCount: filteredRequests.length,
    itemBuilder: (context, index) {
      final item = filteredRequests[index];
      return Card(
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailPage(
                  id: item['id'],
                  is_finished: is_finish,
                ),
              ),
            ).then((_) async{
                   await fetchRequests();
                    setState(() {});
                  });
          },
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
              child: Image.network(
                item['photo_url'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person),
              ),
            ),
          ),
          title: Text(item['shoet_farm_code'] ?? ''),
          subtitle: Text(
              'طلبية رقم :${item['id']} - العملية : ${item['process_name']}'),
        ),
      );
    },
  );
}

  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
          title: Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // إظهار المناطق المختارة بالأعلى
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: selectedAreas2.map((areaCode) {
                    bool isLast = selectedAreas2.last == areaCode;
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorbar_bottom,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(areaCode,
                              style: const TextStyle(
                                  fontSize: 16, color: colorbar)),
                          const SizedBox(width: 4),
                          if (isLast)
                            GestureDetector(
                              onTap: () => removeArea(areaCode),
                              child: const Icon(Icons.close_rounded,
                                  size: 20, color: Colors.red),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Text(user_area),
            ],
          ),
          actions: [
            if (user_respose['user_type'] == 2)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailPage(),
                    ),
                  ).then((_) async{
                   await fetchRequests();
                    setState(() {});
                  });
                },
                child: Text(
                  'إنشاء جديد',
                  style: TextStyle(color: colorbar),
                ),
              ),
            SizedBox(
              width: 10,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                New_user_area2 = user_area;
                new_level2 = user_level + 1;
                print('New_user_area2:$New_user_area2');
                print('new_level2:$new_level2');

                await fetchAreas();
                checked2();
                selectedAreas2.clear();
                await fetchRequests();
                setState(() {});
              },
            ),
          ],
        ),
        body: Row(
          children: [
            // ✅ عمود المناطق
            Container(
              width: 65,
              color: const Color.fromARGB(255, 235, 235, 235),
              child: Column(
                children: areas.map((area) {
                  return GestureDetector(
                    onTap: () => selectArea(area),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorbar,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        area[check_farm2].toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ✅ التابات مع عرض الطلبات
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'طلبات جديدة'),
                        Tab(text: 'انتظار الموافقه'),
                        Tab(text: 'تقييم المسئول'),
                        Tab(text: 'الكل'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildRequestList(filter: 'new',is_finish :0),
                          buildRequestList(filter: 'solved',is_finish :0),
                          buildRequestList(filter: 'pending',is_finish :1),
                          buildRequestList(filter: 'all',is_finish :0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }
}
