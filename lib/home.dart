import 'package:farmplanning/Main_process.dart';
import 'package:farmplanning/MoreScreen.dart';
import 'package:farmplanning/UploadExcelScreen.dart';
import 'package:farmplanning/global.dart';
import 'package:farmplanning/message_users_list_page.dart';
import 'package:farmplanning/proplems2.dart';
import 'package:farmplanning/users.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MainProcessScreen(mainkey:1),
    user_respose['Isadmain'] == 1
        ? UploadExcelScreen(
            type: 0,
          )
        : OrdersScreen(),
    RequestListPage2(),
    //  ChatScreen(),
    MessageUsersListPage(
      currentUserId: user_id,
      currentUserUUID: user_uuid,
    ),
    MainProcessScreen(mainkey:2),
    // UserProfileScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: colorbar_bottom,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorbar,
          unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "رئيسية"),
            BottomNavigationBarItem(
                icon: Icon(Icons.upload_file), label: "تحميل بيانات"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "طلبات"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "مراسلة"),
            BottomNavigationBarItem(
                icon: Icon(Icons.report), label: "تقرير اجمالي"),
            BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz), label: "مزيد"),
          ],
        ),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text("📦 تحميل من اكسل", style: TextStyle(fontSize: 24)));
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("💬 المراسلة", style: TextStyle(fontSize: 24)));
  }
}

// class MoreScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(child: Text("⚙️ المزيد", style: TextStyle(fontSize: 24)));
//   }
// }
