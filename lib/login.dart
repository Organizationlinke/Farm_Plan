

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
