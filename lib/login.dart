
import 'package:farmplanning/Main_process.dart';
import 'package:farmplanning/global.dart';
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
      user_level=response["level"];
      user_area=response["farm_code"];
      farm_title=response["shoet_farm_code"];
      New_user_area=user_area;
    new_level=user_level+1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_enter', userEnter);
      await prefs.setString('pass', pass);
   
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>MainProcessScreen()),
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
        appBar: AppBar(title: Text('تسجيل الدخول')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(controller: _userController, decoration: InputDecoration(labelText: 'اسم المستخدم')),
              TextField(controller: _passController, decoration: InputDecoration(labelText: 'كلمة السر'), obscureText: true),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: Text('دخول')),
            ],
          ),
        ),
      ),
    );
  }
}
