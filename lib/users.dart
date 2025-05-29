import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmplanning/global.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  String? _selectedFarm;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? imageUrl;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await Supabase.instance.client
          .from('usertable')
          .select()
          .eq('id', user_id)
          .single();

      if (!mounted) return;
      setState(() {
        userData = response;
        _nameController.text = userData['user_name'] ?? '';
        _passController.text = userData['pass'] ?? '';
        _selectedFarm = userData['farm_id']?.toString();
        imageUrl = userData['photo_url'];
      });

      if (imageUrl != null && imageUrl!.isNotEmpty) {
        final imageResponse = await http.get(Uri.parse(imageUrl!));
        if (imageResponse.statusCode == 200) {
          if (!mounted) return;
          setState(() {
            _imageBytes = imageResponse.bodyBytes;
          });
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل بيانات المستخدم')),
      );
    }
  }

//   Future<void> _loadUserData() async {
//     try {
//       final response = await Supabase.instance.client
//           .from('usertable')
//           .select()
//           .eq('id', user_id)
//           .single();
// if (!mounted) return;
//       setState(() {
//         userData = response;
//         _nameController.text = userData['user_name'] ?? '';
//         _passController.text = userData['pass'] ?? '';
//         _selectedFarm = userData['farm_id']?.toString();
//         imageUrl = userData['photo_url'];
//       });
//       // تحميل الصورة وتحويلها إلى Uint8List
//       if (imageUrl != null && imageUrl!.isNotEmpty) {
//         print('Image URL: $imageUrl'); // debug
//         final imageResponse = await http.get(Uri.parse(imageUrl!));
//         if (imageResponse.statusCode == 200) {
//           if (!mounted) return;
//           setState(() {
//             _imageBytes = imageResponse.bodyBytes;
//           });
//         } else {
//           print('فشل تحميل الصورة: ${imageResponse.statusCode}');
//         }
//       }
//     } catch (e) {
//       print('Error loading user: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('فشل تحميل بيانات المستخدم')),
//       );
//     }
//   }

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // if (_imageBytes != null) {
      //   // final filePath = 'user_photo/${userData['user_enter']}.png';

      //   final randomFileName = const Uuid().v4(); // اسم عشوائي
      //   final filePath = 'user_photo/$randomFileName.png';

      //   final bucket = Supabase.instance.client.storage.from('user_photo');

      //   // await bucket.remove([filePath]);
      //   final oldUrl = userData['photo_url'];
      //   if (oldUrl != null && oldUrl.contains('user_photo/')) {
      //     final oldPath = oldUrl.split('user_photo/').last;
      //     await bucket.remove(['user_photo/$oldPath']);
      //   }

      //   await bucket.uploadBinary(filePath, _imageBytes!,
      //       fileOptions: const FileOptions(upsert: true));

      //   imageUrl = bucket.getPublicUrl(filePath);
      //   // imageUrl = bucket.getPublicUrl(filePath) + '?t=${DateTime.now().millisecondsSinceEpoch}';
      // }
      if (_imageBytes != null) {
        final bucket = Supabase.instance.client.storage.from('user_photo');

        // حذف الصورة القديمة
        final oldUrl = userData['photo_url'];
        if (oldUrl != null && oldUrl.contains('user_photo/')) {
          final oldPath = oldUrl.split('user_photo/').last;
          await bucket.remove(['user_photo/$oldPath']);
        }

        // رفع صورة جديدة باسم عشوائي
        final randomFileName = const Uuid().v4();
        final filePath = 'user_photo/$randomFileName.png';

        await bucket.uploadBinary(filePath, _imageBytes!,
            fileOptions: const FileOptions(upsert: true));

        imageUrl = bucket.getPublicUrl(filePath);
      }

      await Supabase.instance.client.from('users').update({
        'user_name': _nameController.text,
        'pass': _passController.text,
        'farm_id': int.parse(_selectedFarm!),
        if (imageUrl != null) 'photo_url': imageUrl,
      }).eq('user_enter', userData['user_enter']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث البيانات')),
      );
    } finally {
      await _loadUserData();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: colorbar,
          foregroundColor: Colorapp,
          title: Text('بيانات المستخدم')),
      body: userData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (imageUrl != null
                              ? NetworkImage(imageUrl!) as ImageProvider
                              : AssetImage('assets/default_avatar.png')),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'الاسم كامل'),
                  ),
                  TextField(
                    controller: _passController,
                    decoration: InputDecoration(labelText: 'كلمة السر'),
                  ),
                  SizedBox(height: 16),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 131, 5),
                            foregroundColor: Colors.white),
                          onPressed: _updateProfile,
                          child: Text('تحديث البيانات'),
                        ),
                ],
              ),
            ),
    );
  }
}
