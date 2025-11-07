import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/create_post_page.dart';
import 'api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLoggedIn() async {
    return await ApiService.hasToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social App',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/createPost': (context) => CreatePostPage(),
      },
      home: CreatePostPage()
      
      /*FutureBuilder<bool>(
        future: _checkLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final loggedIn = snapshot.data ?? false;
          return loggedIn ? HomePage() : LoginPage();
        },
      ),*/
    );
  }
}
