import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  File? _image;
  bool _isUploading = false;
  bool _isDeleting = false;
  bool _isUploaded = false;
  bool _isFetching = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isUploaded = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      await supabase.storage.from('images').upload(fileName, _image!);

      final imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
      await supabase.from('image_urls').insert({'url': imageUrl});

      setState(() {
        _isUploaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image uploaded successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _getApiResponse() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No image selected')));
      return;
    }

    final url = Uri.parse('http://34.132.156.254:3000/predict');

    setState(() {
      _isFetching = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Fetching Result"),
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      ),
    );

    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      Navigator.of(context).pop(); // close loading dialog

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Prediction'),
          content: Text(responseBody),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API call failed')));
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _deleteImage() async {
    if (_image == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      setState(() {
        _image = null;
        _isUploaded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image deleted!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed!')));
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture & Upload', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6B1495),
                Color(0xFF613DC1),
                Color(0xFF372D68),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null) ...[
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _isUploading || _isDeleting
                          ? Center(child: CircularProgressIndicator())
                          : Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton("Re-click", _pickImage, Colors.white),
                      SizedBox(height: 10),
                      if (!_isUploaded)
                        _buildButton("Upload", _uploadImage, Colors.white),
                      if (_isUploaded)
                        _buildButton("Get Api response", _getApiResponse, Colors.white),
                      SizedBox(height: 10),
                      _buildButton("Delete", _deleteImage, Colors.white),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              if (_image == null)
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Take Picture"),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return Container(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
        child: Text(text),
      ),
    );
  }
}
