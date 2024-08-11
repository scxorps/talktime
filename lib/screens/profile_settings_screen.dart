import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';



class ProfileSettings extends StatefulWidget {
  static const String screenRoute = 'profile_settings';
  const ProfileSettings({super.key});

  @override
  _ProfileSettingsState createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  User? user;
  XFile? _image;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          this.user = user;
        });

        // Fetch user info from Firestore
        final userDoc = await _firestore.collection('current_users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          _emailController.text = data?['email'] ?? '';
          _usernameController.text = data?['username'] ?? '';
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user information.')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null && user != null) {
      try {
        final storageRef = _storage.ref().child('profile_pictures/${user!.uid}');
        final Uint8List imageBytes = await _image!.readAsBytes();
        final uploadTask = storageRef.putData(imageBytes);
        await uploadTask.whenComplete(() => null);
        final downloadUrl = await storageRef.getDownloadURL();
        await _firestore.collection('current_users').doc(user!.uid).update({
          'profile_picture': downloadUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image.')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (user != null) {
      try {
        // Update user profile info
        await user!.updateProfile(displayName: _usernameController.text);
        await user!.updateEmail(_emailController.text);
        if (_passwordController.text.isNotEmpty) {
          await user!.updatePassword(_passwordController.text);
        }
        await _firestore.collection('current_users').doc(user!.uid).update({
          'username': _usernameController.text,
          'email': _emailController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _image != null ? FileImage(File(_image!.path)) : null,
                child: _image == null
                    ? Icon(Icons.camera_alt, size: 50, color: Colors.grey[800])
                    : null,
              ),
            ),
          ),
          SizedBox(height: 16.0),
          Center(
            child: ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Update Image'),
            ),
          ),
          SizedBox(height: 24.0),
          Text('Username:', style: TextStyle(fontSize: 18)),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your username',
            ),
          ),
          SizedBox(height: 16.0),
          Text('Email:', style: TextStyle(fontSize: 18)),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your email',
            ),
          ),
          SizedBox(height: 16.0),
          Text('Password:', style: TextStyle(fontSize: 18)),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your new password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 24.0),
          Center(
            child: ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
          ),
        ],
      ),
    );
  }
}
