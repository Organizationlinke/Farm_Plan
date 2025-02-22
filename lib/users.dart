
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  UserProfileScreen({required this.userData});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  String? _selectedFarm;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['user_name'];
    _passController.text = widget.userData['pass'];
    _selectedFarm = widget.userData['farm_id'].toString();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    String? imageUrl;
    if (_image != null) {
      final imageBytes = await _image!.readAsBytes();
      final response = await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary('${widget.userData['user_enter']}.png', imageBytes);
      imageUrl = response;
    }

    await Supabase.instance.client.from('users').update({
      'user_name': _nameController.text,
      'pass': _passController.text,
      'farm_id': int.parse(_selectedFarm!),
      if (imageUrl != null) 'photo_url': imageUrl,
    }).eq('user_enter', widget.userData['user_enter']);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث البيانات بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('بيانات المستخدم')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : widget.userData['photo_url'] != null
                        ? NetworkImage(widget.userData['photo_url']) as ImageProvider
                        : AssetImage('assets/default_avatar.png'),
              ),
            ),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'الاسم كامل')),
            TextField(controller: _passController, decoration: InputDecoration(labelText: 'كلمة السر')),
            FutureBuilder(
              future: Supabase.instance.client.from('farm').select(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final farms = snapshot.data as List<dynamic>;
                return DropdownButton<String>(
                  value: _selectedFarm,
                  onChanged: (value) => setState(() => _selectedFarm = value),
                  items: farms.map<DropdownMenuItem<String>>((farm) {
                    return DropdownMenuItem<String>(
                      value: farm['id'].toString(),
                      child: Text(farm['farm_code']),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _updateProfile, child: Text('تحديث البيانات')),
          ],
        ),
      ),
    );
  }
}