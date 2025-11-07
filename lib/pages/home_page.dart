import 'package:flutter/material.dart';
import '../api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.fetchPosts();

      posts = List<Map<String, dynamic>>.from(
        fetched.map((p) {
          // Data structure example:
          // {
          //   "id": 1,
          //   "title": "...",
          //   "content": "...",
          //   "user": { "id": 3, "name": "Ali" },
          //   "image": "uploads/posts/photo.jpg"
          // }

          String username = 'Anonymous';
          if (p['user'] != null) {
            if (p['user'] is Map && p['user']['name'] != null) {
              username = p['user']['name'];
            } else if (p['user'] is String) {
              username = p['user'];
            }
          }

          // Handle image URL
          String? imageUrl = p['image'];
          if (imageUrl != null &&
              imageUrl.isNotEmpty &&
              !imageUrl.startsWith('http')) {
            imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/$imageUrl';
          }

          return {
            'id': p['id'],
            'user': username,
            'title': p['title'] ?? '',
            'content': p['content'] ?? '',
            'likes': p['likes'] ?? p['like_count'] ?? 0,
            'image': imageUrl,
            'created_at': p['created_at'] ?? '',
          };
        }),
      );

      // If no posts were fetched, use mock data
      if (posts.isEmpty) {
        posts = _mockPosts;
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      posts = _mockPosts;
    } finally {
      setState(() => isLoading = false);
    }
  }

  void addLike(int index) async {
    final post = posts[index];
    final postId = post['id'];

    setState(() => posts[index]['likes'] = (post['likes'] ?? 0) + 1);

    if (postId != null) {
      final ok = await ApiService.likePost(postId);
      if (!ok) {
        setState(() => posts[index]['likes'] = (post['likes'] ?? 1) - 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to like the post.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/createPost');
          if (result == true) await loadPosts();
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadPosts,
              child: posts.isEmpty
                  ? const Center(
                      child: Text(
                        'No posts yet',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final username = post['user'] ?? 'User';
                        final title = post['title'] ?? '';
                        final content = post['content'] ?? '';
                        final likes = post['likes'] ?? 0;
                        final imageUrl = post['image'];
                        final date = post['created_at'] ?? 'Now';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(username[0].toUpperCase()),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            date.toString(),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                if (title.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  content,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      height: 200,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey[200],
                                        height: 200,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_up_alt_outlined,
                                            color: Colors.blueAccent,
                                          ),
                                          onPressed: () => addLike(index),
                                        ),
                                        Text(
                                          '$likes likes',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.comment_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

//  بيانات مؤقتة في حال لم يُرجع الخادم شيئًا
final List<Map<String, dynamic>> _mockPosts = [
  {
    'id': 1,
    'user': 'Ali',
    'title': 'A Day in Nature 🌳',
    'content': 'I enjoyed the nature a lot!',
    'likes': 12,
    'image':
        'https://images.unsplash.com/photo-1508261301920-1b59a848b8f0?w=800',
    'created_at': '2025-11-01',
  },
  {
    'id': 2,
    'user': 'Sara',
    'title': 'Morning Coffee ☕',
    'content': 'Nothing beats a cup of coffee on a beautiful morning!',
    'likes': 30,
    'image':
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800',
    'created_at': '2025-10-30',
  },
  {
    'id': 3,
    'user': 'Omar',
    'title': 'My New Book 📚',
    'content': 'I started writing the first chapter of my new novel today!',
    'likes': 8,
    'image':
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800',
    'created_at': '2025-10-28',
  },
];
