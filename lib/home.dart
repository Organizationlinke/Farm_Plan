import 'package:farmplanning/Main_process.dart';
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
    MainProcessScreen(),
    OrdersScreen(),
    ChatScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "رئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "طلبات"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "مراسلة"),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "مزيد"),
          ],
        ),
      ),
    );
  }
}



class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("📦 الطلبات", style: TextStyle(fontSize: 24)));
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("💬 المراسلة", style: TextStyle(fontSize: 24)));
  }
}

class MoreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("⚙️ المزيد", style: TextStyle(fontSize: 24)));
  }
}
