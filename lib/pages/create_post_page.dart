import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final contentController = TextEditingController();
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  // لاختيار الصورة من الجهاز
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // إرسال المنشور إلى API
  void submitPost() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى كتابة محتوى المنشور')),
      );
      return;
    }

    bool success = await ApiService.createPost(content, imagePath: _selectedImage?.path);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم نشر المنشور بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في نشر المنشور')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إنشاء منشور')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'محتوى المنشور'),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            _selectedImage != null
                ? Column(
                    children: [
                      Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: Icon(Icons.close),
                        label: Text('إزالة الصورة'),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: pickImage,
                    icon: Icon(Icons.image),
                    label: Text('اختيار صورة (اختياري)'),
                  ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: submitPost, child: Text('نشر')),
          ],
        ),
      ),
    );
  }
}

