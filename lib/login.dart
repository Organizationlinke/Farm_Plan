

import 'package:farmplanning/global.dart';
import 'package:farmplanning/home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
  
    _loadSavedCredentials();
    
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _userController.text = prefs.getString('user_enter') ?? '';
    _passController.text = prefs.getString('pass') ?? '';
  }
// login_screen.dart -> _login()

// login_screen.dart -> _login()
// login_screen.dart -> _login()

// Future<void> _login() async {
//   final userEnter = _userController.text;
//   final pass = _passController.text;

//   // 1. جلب بيانات المستخدم الأساسية
//   final userResponse = await Supabase.instance.client
//       .from('users')
//       .select()
//       .eq('user_enter', userEnter)
//       .eq('pass', pass)
//       .single();

//   if (userResponse.isEmpty) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('اسم المستخدم أو كلمة السر غير صحيحة')),
//       );
//     }
//     return;
//   }

//   // حفظ بيانات المستخدم
//   user_id = userResponse["id"];
//   user_respose = userResponse;
//   // ... (حفظ باقي بيانات المستخدم)

//   // 2. جلب كل farm_id المسؤول عنها المستخدم
//   final responsibilitiesResponse = await Supabase.instance.client
//       .from('usertable')
//       .select('farm_id')
//       .eq('id', user_id);
      
//   final List<dynamic> farmIds = responsibilitiesResponse
//       .map((item) => item['farm_id'])
//       .toList();

//   if (farmIds.isEmpty) {
//       print("هذا المستخدم ليس لديه أي مناطق مسؤولية.");
//       return;
//   }

//   // --- التعديل النهائي هنا ---

//   // 3. تحويل قائمة الأرقام إلى نص بالصيغة المطلوبة
//   final String idListString = '(${farmIds.join(',')})';

//   // 4. استخدام دالة filter لجلب البيانات
//   final farmCodesResponse = await Supabase.instance.client
//       .from('farm')
//       .select('farm_code')
//       .filter('id', 'in', idListString); // ✅ الطريقة المضمونة

//   // --- نهاية التعديل ---

//   // تخزين قائمة الأكواد في المتغير العام
//   user_responsible_areas = farmCodesResponse
//       .map<String>((item) => item['farm_code'] as String)
//       .toList();

//   if (user_responsible_areas.isNotEmpty) {
//     New_user_area = user_responsible_areas[0];
//     New_user_area2 = user_responsible_areas[0];
//   }
  
//   // ... (باقي كود تسجيل الدخول)
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setString('user_enter', userEnter);
//   await prefs.setString('pass', pass);

//   if (mounted) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => MainScreen()),
//     );
//   }
// }
  Future<void> _login() async {
    final userEnter = _userController.text;
    final pass = _passController.text;

    final response = await Supabase.instance.client
        .from('usertable')
        .select()
        .eq('user_enter', userEnter)
        .eq('pass', pass)
        .single();

    if (response .isNotEmpty) {
      user_id=response["id"];
      user_uuid=response["uuid"];
      user_respose=response;
      user_level=response["level"];
      user_area=response["farm_code"];
      farm_title=response["shoet_farm_code"];
      New_user_area=user_area;
      New_user_area2=user_area;
      user_type=response["user_type"];
      print('user_type:$user_type');
    new_level=user_level+1;
    new_level2=user_level+1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_enter', userEnter);
      await prefs.setString('pass', pass);
   
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>MainScreen()),
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => UserProfileScreen(userData: response)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اسم المستخدم أو كلمة السر غير صحيحة')),
      );
    }
 
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
          title: Text('شاشة تسجيل الدخول')
          ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
               width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network('https://rfnklwurcdgbfjsatato.supabase.co/storage/v1/object/public/user_photo//logo2.png',
                  width: 300,),
                    // Text('شاشة تسجيل الدخول',style: TextStyle(fontSize: 25),),
                    SizedBox(height: 50),
                  TextField(controller: _userController, decoration: InputDecoration(labelText: 'اسم المستخدم',icon: Icon(Icons.person,color: Colors.green,))),
                  TextField(controller: _passController, decoration: InputDecoration(labelText: 'كلمة المرور',icon: Icon(Icons.lock,color: Colors.blue,)), obscureText: true),
                  SizedBox(height: 20),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                      backgroundColor:const Color.fromARGB(255, 1, 131, 5),
                      foregroundColor: Colors.white
                    ),
                    onPressed: _login, child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('تسجيل الدخول',style: TextStyle(fontSize: 18),),
                    )),
                  SizedBox(height: 200),
               
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
