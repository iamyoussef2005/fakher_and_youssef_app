import 'package:fakher_youssef/api_service.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void register() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();
  final confirm = confirmPasswordController.text.trim();

  if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('يرجى ملء جميع الحقول')),
    );
    return;
  }

  if (password != confirm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('كلمة المرور غير متطابقة')),
    );
    return;
  }

  bool success = await ApiService.register(email, password, confirm);
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إنشاء الحساب بنجاح ✅')),
    );
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('فشل في إنشاء الحساب ❌')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create an account')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: confirmPasswordController, decoration: InputDecoration(labelText: 'Confirm password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text('Sign up')),
          ],
        ),
      ),
    );
  }
}
