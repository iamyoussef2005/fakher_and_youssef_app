import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// This class handles all communication between the Flutter app and the backend API.
// It includes authentication (login/register), profile management, and post management.
// It also stores the authentication token locally using SharedPreferences.
class ApiService {
  // Base URL for your Laravel API
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // -----------------------------
  // 🔹 TOKEN MANAGEMENT FUNCTIONS
  // -----------------------------

  // Saves the authentication token securely in local storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Retrieves the saved authentication token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Public helper function to check if a token exists (user logged in)
  static Future<bool> hasToken() async {
    final t = await _getToken();
    return t != null && t.isNotEmpty;
  }

  // Logs the user out by removing the stored token
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // _____________________________________________________________________
  // _____________________________________________________________________
  // _____________________________________________________________________
  //                🔐 AUTHENTICATION FUNCTIONS 🔐
  // _____________________________________________________________________
  // _____________________________________________________________________
  // _____________________________________________________________________

  // Registers a new user by sending data to /register
  static Future<bool> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'username': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      // Laravel typically returns 200 or 201 on successful registration
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful — no token expected here
        return true;
      } else {
        print('register failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('register error: $e');
    }
    return false;
  }

  // Logs in the user and saves the token if successful
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Different Laravel responses may use different token keys
        final token =
            data['token'] ?? data['access_token'] ?? data['data']?['token'];

        // Save token locally if it exists
        if (token != null) await _saveToken(token.toString());
        return true;
      } else {
        print('login failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('login error: $e');
    }
    return false;
  }

  // _____________________________________________________________________
  // _____________________________________________________________________
  //                    POSTS MANAGEMENT FUNCTIONS
  // _____________________________________________________________________
  // _____________________________________________________________________

  // Fetches all available posts (general feed)
  static Future<List<dynamic>> fetchPosts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different possible response structures
        if (data is Map && data['posts'] != null) {
          return List.from(data['posts']);
        }
        if (data is List) return data;

        // In case the response has an unexpected format
        return [data];
      } else {
        print('fetchPosts failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('fetchPosts error: $e');
    }
    return [];
  }

  // Creates a new post (can include text, image, and optional timestamp)
  static Future<bool> createPost(
    String body, {
    String? title,
    String? image,
  }) async {
    try {
      final token = await _getToken();

      // Multipart request is required when uploading files (image)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['content'] = body;

      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }

      // Attach image if provided
      if (image != null && image.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', image));
      }

      // Send request and handle response
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (streamed.statusCode == 201 || streamed.statusCode == 200) {
        return true;
      } else {
        print('createPost failed: ${streamed.statusCode} ${response.body}');
      }
    } catch (e) {
      print('createPost error: $e');
    }
    return false;
  }

  // Likes or unlikes a post by ID
  // Like a post using GET request (API: /api/homePage/like/{postId})
  static Future<bool> likePost(int id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/homePage/like/$id',
        ), 
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('likePost failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('likePost error: $e');
    }
    return false;
  }

  // Dislike a post using GET request (API: /api/homePage/dislike/{postId})
  static Future<bool> dislikePost(int id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/homePage/dislike/$id',
        ), 
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('dislikePost failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('dislikePost error: $e');
    }
    return false;
  }

  // -----------------------------
  // 🔹 USER PROFILE FUNCTIONS
  // -----------------------------

  // Retrieves the authenticated user's profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('getUserProfile failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('getUserProfile error: $e');
    }
    return null;
  }

  // Fetches the posts created by the currently logged-in user
  static Future<List<dynamic>> fetchUserPosts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/user/posts'),
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['posts'] != null) {
          return List.from(data['posts']);
        }
      } else {
        print('fetchUserPosts failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('fetchUserPosts error: $e');
    }
    return [];
  }




  //   static Future<List<dynamic>> fetchPosts() async {
  //   try {
  //     final token = await _getToken();
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/posts'),
  //       headers: {'Authorization': token != null ? 'Bearer $token' : ''},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       // Handle different possible response structures
  //       if (data is Map && data['posts'] != null) {
  //         return List.from(data['posts']);
  //       }
  //       if (data is List) return data;

  //       // In case the response has an unexpected format
  //       return [data];
  //     } else {
  //       print('fetchPosts failed: ${response.statusCode} ${response.body}');
  //     }
  //   } catch (e) {
  //     print('fetchPosts error: $e');
  //   }
  //   return [];
  // }

  // Deletes a specific post by ID
  static Future<bool> deletePost(int id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$id'),
        headers: {'Authorization': token != null ? 'Bearer $token' : ''},
      );
      if (response.statusCode == 200) return true;
      print('deletePost failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('deletePost error: $e');
    }
    return false;
  }

  // Updates a post (title, content, or image)
  static Future<bool> updatePost(
    int id, {
    String? title,
    String? body,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest(
        'POST', // Some APIs may use PUT/PATCH — adjust if necessary
        Uri.parse('$baseUrl/posts/$id'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (title != null) request.fields['title'] = title;
      if (body != null) request.fields['content'] = body;
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      final streamed = await request.send();
      if (streamed.statusCode == 200) return true;
      final response = await http.Response.fromStream(streamed);
      print('updatePost failed: ${streamed.statusCode} ${response.body}');
    } catch (e) {
      print('updatePost error: $e');
    }
    return false;
  }

  // Updates the user's profile info (name and/or avatar)
  static Future<bool> updateProfile({String? name, String? avatarPath}) async {
    try {
      final token = await _getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/update'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (name != null) request.fields['name'] = name;
      if (avatarPath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', avatarPath),
        );
      }

      final streamed = await request.send();
      if (streamed.statusCode == 200) return true;
      final response = await http.Response.fromStream(streamed);
      print('updateProfile failed: ${streamed.statusCode} ${response.body}');
    } catch (e) {
      print('updateProfile error: $e');
    }
    return false;
  }
}
