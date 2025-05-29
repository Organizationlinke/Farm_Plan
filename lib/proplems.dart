// استورد الحزم المطلوبة
import 'package:farmplanning/RequestDetailPage.dart';
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: RequestListPage(),
//     );
//   }
// }

// الشاشة الأولى: قائمة الطلبات
class RequestListPage extends StatefulWidget {
  @override
  _RequestListPageState createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  List<dynamic> requests = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    final response =
        await Supabase.instance.client.from('proplems_view').select();
    if (!mounted) return;
    setState(() {
      requests = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorbar,
        foregroundColor: Colorapp,
        title: Text('الطلبات'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailPage(),
                ),
              );
            },
            child: Text('إنشاء جديد'),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final item = requests[index];
          return Card(
            child: ListTile(
              title: Text(item['shoet_farm_code'] ?? ''),
              subtitle: Text(item['process_name'] ?? ''),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 1, 131, 5),
                    foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailPage(id: item['id']),
                    ),
                  );
                },
                child: Text('عرض'),
              ),
            ),
          );
        },
      ),
    );
  }
}
