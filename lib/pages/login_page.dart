import 'package:fakher_youssef/api_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('يرجى إدخال الإيميل وكلمة المرور')),
    );
    return;
  }

  bool success = await ApiService.login(email, password);
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تسجيل الدخول ✅')),
    );
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('فشل تسجيل الدخول ❌')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log in')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text('Log in')),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text('Create an account'),
            )
          ],
        ),
      ),
    );
  }
}
