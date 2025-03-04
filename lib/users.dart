import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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
  Uint8List? _imageBytes; // استخدم `Uint8List` بدلاً من `File`
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['user_name'];
    _passController.text = widget.userData['pass'];
    _selectedFarm = widget.userData['farm_id'].toString();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes; // حفظ الصورة كـ `Uint8List`
      });
    }
  }

  Future<void> _updateProfile() async {
    String? imageUrl;
    
    if (_imageBytes != null) {
      try {
        final filePath = 'user_photo/${widget.userData['user_enter']}.png';

        // ✅ رفع الصورة باستخدام `uploadBinary`
        await Supabase.instance.client.storage
            .from('user_photo')
            .uploadBinary(filePath, _imageBytes!, fileOptions: const FileOptions(upsert: true));

        // ✅ الحصول على الرابط العام للصورة
        imageUrl = Supabase.instance.client.storage.from('user_photo').getPublicUrl(filePath);

        setState(() {
          widget.userData['photo_url'] = imageUrl;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')),
        );
        return;
      }
    }

    // ✅ تحديث بيانات المستخدم
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
                backgroundImage: _imageBytes != null
                    ? MemoryImage(_imageBytes!) // استخدم `MemoryImage` بدلاً من `FileImage`
                    : widget.userData['photo_url'] != null
                        ? NetworkImage(widget.userData['photo_url']) as ImageProvider
                        : NetworkImage('https://rfnklwurcdgbfjsatato.supabase.co/storage/v1/object/public/user_photo/default_avatar.png'),
              ),
            ),

            
           
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'الاسم كامل')),
            TextField(controller: _passController, decoration: InputDecoration(labelText: 'كلمة السر')),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _updateProfile, child: Text('تحديث البيانات')),
          ],
        ),
      ),
    );
  }
}


// import 'dart:io';
// import 'package:farmplanning/global.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class UserProfileScreen extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   UserProfileScreen({required this.userData});

//   @override
//   _UserProfileScreenState createState() => _UserProfileScreenState();
// }

// class _UserProfileScreenState extends State<UserProfileScreen> {
//   final _nameController = TextEditingController();
//   final _passController = TextEditingController();
//   String? _selectedFarm;
//   File? _image;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _nameController.text = widget.userData['user_name'];
//     _passController.text = widget.userData['pass'];
//     _selectedFarm = widget.userData['farm_id'].toString();
//   }
// //  Future<void> _login() async {
  

// //     final response = await Supabase.instance.client
// //         .from('usertable')
// //         .select()
// //         .eq('id', user_id)
// //         .single();
// //  }
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().pickImage(source: source);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }
// Future<void> _updateProfile() async {
//   String? imageUrl;
  
//   if (_image != null) {
//     try {
//       final filePath = 'user_photo/${widget.userData['user_enter']}.png';

//       // رفع الصورة إلى Supabase
//       await Supabase.instance.client.storage
//           .from('user_photo')
//           .upload(filePath, _image!, fileOptions: const FileOptions(upsert: true));

//       // الحصول على الرابط العام
//       imageUrl = Supabase.instance.client.storage.from('user_photo').getPublicUrl(filePath);

//       // ✅ تحديث الحالة فورًا بعد رفع الصورة
//       setState(() {
//         widget.userData['photo_url'] = imageUrl;
//       });

//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')),
//       );
//       return;
//     }
//   }

//   // تحديث بيانات المستخدم في الجدول
//   await Supabase.instance.client.from('users').update({
//     'user_name': _nameController.text,
//     'pass': _passController.text,
//     'farm_id': int.parse(_selectedFarm!),
//     if (imageUrl != null) 'photo_url': imageUrl,
//   }).eq('user_enter', widget.userData['user_enter']);

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text('تم تحديث البيانات بنجاح')),
//   );
// }



//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('بيانات المستخدم')),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: () => _pickImage(ImageSource.gallery),
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: _image != null
//                     ? FileImage(_image!)
//                     : widget.userData['photo_url'] != null
//                         ? NetworkImage(widget.userData['photo_url']) as ImageProvider
//                         : NetworkImage('https://rfnklwurcdgbfjsatato.supabase.co/storage/v1/object/public/user_photo/default_avatar.png'),
//               ),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(icon: Icon(Icons.photo_library), onPressed: () => _pickImage(ImageSource.gallery)),
//                 IconButton(icon: Icon(Icons.camera_alt), onPressed: () => _pickImage(ImageSource.camera)),
//               ],
//             ),
//             TextField(controller: _nameController, decoration: InputDecoration(labelText: 'الاسم كامل')),
//             TextField(controller: _passController, decoration: InputDecoration(labelText: 'كلمة السر')),
//             FutureBuilder(
//               future: Supabase.instance.client.from('farm').select(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return CircularProgressIndicator();
//                 }
//                 if (!snapshot.hasData || snapshot.hasError) {
//                   return Text('تعذر تحميل قائمة المزارع');
//                 }
//                 final farms = snapshot.data as List<dynamic>;
//                 return DropdownButton<String>(
//                   value: _selectedFarm,
//                   onChanged: (value) => setState(() => _selectedFarm = value),
//                   items: farms.map<DropdownMenuItem<String>>((farm) {
//                     return DropdownMenuItem<String>(
//                       value: farm['id'].toString(),
//                       child: Text(farm['farm_code']),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//             SizedBox(height: 20),
//             _isLoading
//                 ? CircularProgressIndicator()
//                 : ElevatedButton(onPressed: _updateProfile, child: Text('تحديث البيانات')),
//           ],
//         ),
//       ),
//     );
//   }
// }

