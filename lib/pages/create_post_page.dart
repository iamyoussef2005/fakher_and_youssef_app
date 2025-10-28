import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

// This widget represents a page for creating a new post.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // Controllers for the title and content text fields.
  final contentController = TextEditingController();
  final titleController = TextEditingController();

  // To store the selected image file.
  File? _selectedImage;

  // Image picker instance to access the user's gallery.
  final ImagePicker _picker = ImagePicker();

  // To indicate whether the post is being uploaded (for showing a loading spinner).
  bool isLoading = false;

  // Function to let the user pick an image from the gallery.
  Future<void> pickImage() async {
    // Opens the image gallery and waits for user selection.
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // If an image is selected, save it to _selectedImage and refresh the UI.
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Function to handle the submission of the post.
  void submitPost() async {
    // Get the values of title and content and trim extra spaces.
    final content = contentController.text.trim();
    final title = titleController.text.trim();

    // If either field is empty, show a warning message and stop.
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill title and content')));
      return;
    }

    // Start showing loading spinner.
    setState(() => isLoading = true);
    try {
      // Get the current timestamp in ISO8601 format.
      final now = DateTime.now().toIso8601String();

      // Call the API service to create a post.
      bool success = await ApiService.createPost(
        content,
        title: title,
        imagePath: _selectedImage?.path, // Optional image path.
        createdAt: now, // Current timestamp.
      );

      // If successful, show a success message and go back to the previous page.
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Posted!')));
        Navigator.pop(
          context,
          true,
        ); // Return true so the previous page knows to refresh.
      } else {
        // If not successful, show an error message.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Posting Failed')));
      }
    } catch (e) {
      // Catch any exceptions (e.g., network issues) and print the error.
      print('create post error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error happened')));
    } finally {
      // Whether successful or not, stop showing the loading spinner if the widget is still mounted.
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is destroyed to free resources.
    contentController.dispose();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The UI of the Create Post page.
    return Scaffold(
      appBar: AppBar(title: Text('Create a post')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Input field for post title.
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Post title'),
            ),
            SizedBox(height: 30),

            // Input field for post content.
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Post content here'),
              maxLines: 5, // Allows multiple lines for content text.
            ),
            SizedBox(height: 16),

            // If an image is selected, display it with an option to remove it.
            _selectedImage != null
                ? Column(
                    children: [
                      Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover, // Scale image to fit width properly.
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: Icon(Icons.close),
                        label: Text('Remove the photo'),
                      ),
                    ],
                  )
                // If no image selected, show button to pick one.
                : TextButton.icon(
                    onPressed: pickImage,
                    icon: Icon(Icons.image),
                    label: Text('Choose a pic (optional)'),
                  ),

            SizedBox(height: 20),

            // If loading, show spinner, else show "Post" button.
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: submitPost, child: Text('Post')),
          ],
        ),
      ),
    );
  }
}
