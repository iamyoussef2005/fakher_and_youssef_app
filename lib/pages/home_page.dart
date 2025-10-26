import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> posts = [
    {'user': 'يوسف', 'content': 'أول منشور لي!', 'likes': 2},
    {'user': 'فخر', 'content': 'أحب لارافيل ❤️', 'likes': 5},
  ];

  void addLike(int index) {
    setState(() {
      posts[index]['likes']++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home page'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/createPost'),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(post['user']),
              subtitle: Text(post['content']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${post['likes']}'),
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    onPressed: () => addLike(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
