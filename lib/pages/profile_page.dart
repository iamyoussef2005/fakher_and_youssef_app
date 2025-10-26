import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String? imageUrl;
  File? avatar;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  // جلب بيانات المستخدم من Laravel
  void loadUserProfile() async {
    final user = await ApiService.getUserProfile();
    if (user != null) {
      setState(() {
        username = user['name'] ?? '';
        imageUrl = user['avatar'] != null
            ? 'http://127.0.0.1:8000/storage/${user['avatar']}'
            : null;
      });
    }
  }

  // اختيار صورة جديدة من الجهاز
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => avatar = File(picked.path));
    }
  }

  // تحديث البروفايل (اسم وصورة)
  void updateProfile() async {
    bool success = await ApiService.updateProfile(
      name: username,
      avatarPath: avatar?.path,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم حفظ التغييرات بنجاح')),
      );
      loadUserProfile(); // تحديث البيانات المعروضة
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل في تحديث البيانات')),
      );
    }
  }

  // تسجيل خروج المستخدم
  void logout() async {
    await ApiService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الملف الشخصي'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // صورة المستخدم
            CircleAvatar(
              radius: 60,
              backgroundImage: avatar != null
                  ? FileImage(avatar!)
                  : (imageUrl != null ? NetworkImage(imageUrl!) : null)
                      as ImageProvider?,
              child: avatar == null && imageUrl == null
                  ? Icon(Icons.person, size: 60)
                  : null,
            ),

            // زر اختيار صورة
            TextButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.image),
              label: Text('تغيير الصورة'),
            ),

            SizedBox(height: 20),

            // تعديل الاسم
            TextField(
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: username)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: username.length),
                ),
              onChanged: (v) => username = v,
            ),

            SizedBox(height: 20),

            // زر حفظ
            ElevatedButton.icon(
              onPressed: updateProfile,
              icon: Icon(Icons.save),
              label: Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}
