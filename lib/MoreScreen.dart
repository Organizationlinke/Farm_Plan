
import 'package:farmplanning/ItemsScreen.dart';
import 'package:farmplanning/ProcessScreen.dart';
import 'package:farmplanning/UploadExcelScreen.dart';
import 'package:farmplanning/global.dart';
import 'package:farmplanning/login.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("البيانات الاساسية"),
      backgroundColor: colorbar,
          foregroundColor: Colorapp,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings,color: Colors.blue,),
            title: const Text("تعريف العمليات"),
            onTap: () {
               if(user_respose['Isadmain']==1)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProcessScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category,color: Colors.purple),
            title: const Text("تعريف الأصناف"),
            onTap: () {
              if(user_respose['Isadmain']==1)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ItemsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading:  const Icon(Icons.upload,color: Colors.green),
            title: const Text("تحميلات الاكسل"),
            onTap: () {
             if(user_respose['Isadmain']==1)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  UploadExcelScreen(type:1)),
              );
            },
          ),
             const Divider(),
          ListTile(
            leading: const Icon(Icons.logout,color: Colors.red),
            title: const Text("تسجيل الخروج"),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
