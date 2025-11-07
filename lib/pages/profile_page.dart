import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String? imageUrl;
  File? avatar;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  List<Map<String, dynamic>> userPosts = [];

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> loadUserProfile() async {
    setState(() => isLoading = true);
    try {
      final user = await ApiService.getUserProfile();
      final posts = await ApiService.fetchUserPosts();

      if (user != null) {
        setState(() {
          username = user['name'] ?? '';
          imageUrl = user['avatar'] != null
              ? 'http://127.0.0.1:8000/storage/${user['avatar']}'
              : null;
          usernameController.text = username;
          userPosts = List<Map<String, dynamic>>.from(posts);
        });
      }
    } catch (e) {
      print('Profile load error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => avatar = File(picked.path));
    }
  }

  Future<void> updateProfile() async {
    setState(() => isLoading = true);
    try {
      final success = await ApiService.updateProfile(
        name: usernameController.text.trim(),
        avatarPath: avatar?.path,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully')),
        );
        loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to update profile')),
        );
      }
    } catch (e) {
      print('Update profile error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while updating')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deletePost(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.deletePost(id);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Post deleted')),
        );
        setState(() => userPosts.removeWhere((p) => p['id'] == id));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to delete post')),
        );
      }
    }
  }

  Future<void> editPost(Map<String, dynamic> post) async {
    final titleController = TextEditingController(text: post['title'] ?? '');
    final contentController = TextEditingController(text: post['content'] ?? '');

    final updated = await showDialog<Map<String, String>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {
              'title': titleController.text.trim(),
              'content': contentController.text.trim(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null) {
      final ok = await ApiService.updatePost(
        post['id'],
        title: updated['title'],
        body: updated['content'],
      );

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Post updated successfully')),
        );
        loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to update post')),
        );
      }
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 30),
                    _buildPostsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: avatar != null
                    ? FileImage(avatar!)
                    : (imageUrl != null ? NetworkImage(imageUrl!) : null) as ImageProvider?,
                backgroundColor: Colors.grey.shade200,
                child: avatar == null && imageUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: usernameController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: updateProfile,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Posts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          userPosts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No posts yet 😅', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Column(
                  children: userPosts.map((p) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        title: Text(p['title'] ?? 'Untitled',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            p['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => editPost(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => deletePost(p['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
