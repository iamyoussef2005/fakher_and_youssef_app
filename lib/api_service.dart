import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // حفظ التوكن بعد تسجيل الدخول أو التسجيل
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // جلب التوكن من التخزين المحلي
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // DELETE TOKEN WHEN LOG OUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // REGISTER NEW USER
  static Future<bool> register(String email, String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      return true;
    }
    return false;
  }

  // LOG IN 
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      return true;
    }
    return false;
  }






  static Future<List<dynamic>> fetchPosts() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['posts'];
    }
    return [];
  }





static Future<bool> createPost(String content, {String? imagePath}) async {
  final token = await _getToken();

  var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));
  request.headers['Authorization'] = 'Bearer $token';
  request.fields['content'] = content;

  if (imagePath != null && imagePath.isNotEmpty) {
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
  }

  final response = await request.send();
  return response.statusCode == 201;
}


  





  static Future<bool> likePost(int postId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  






  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }





  static Future<bool> updateProfile({String? name, String? avatarPath}) async {
    final token = await _getToken();

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/update'));
    request.headers['Authorization'] = 'Bearer $token';
    if (name != null) request.fields['name'] = name;
    if (avatarPath != null) {
      request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }
}
