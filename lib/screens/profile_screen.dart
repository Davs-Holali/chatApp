// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  File? _imageFile;
  String? _profileImageUrl;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPublicPhone = true;
  bool _isPublicAddress = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = auth.currentUser;
    final userDoc = await firestore.collection('users').doc(user!.uid).get();
    setState(() {
      _firstName = userDoc['firstName'] ?? '';
      _lastName = userDoc['lastName'] ?? '';
      _profileImageUrl = userDoc['profileImageUrl'];
      _email = userDoc['email'] ?? '';
      _phone = userDoc['phone'] ?? '';
      _address = userDoc['address'] ?? '';
      _isPublicPhone = userDoc['isPublicPhone'] ?? true;
      _isPublicAddress = userDoc['isPublicAddress'] ?? true;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImageUrl = _imageFile!.path; // Set image path to display immediately
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = auth.currentUser;
      final storageRef = storage.ref().child('profile_images').child('${user!.uid}.jpg');
      final uploadTask = storageRef.putFile(_imageFile!);

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateProfileField(String field, String value) async {
    final user = auth.currentUser;
    await firestore.collection('users').doc(user!.uid).update({field: value});
    setState(() {
      switch (field) {
        case 'firstName':
          _firstName = value;
          break;
        case 'lastName':
          _lastName = value;
          break;
        case 'phone':
          _phone = value;
          break;
        case 'address':
          _address = value;
          break;
      }
    });
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateProfileField(field, controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? (_profileImageUrl!.startsWith('http') ? NetworkImage(_profileImageUrl!) : FileImage(File(_profileImageUrl!))) as ImageProvider
                          : const AssetImage('assets/profile.png'),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('First Name: $_firstName'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog('firstName', _firstName);
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Last Name: $_lastName'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog('lastName', _lastName);
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Email: $_email'),
                      ),
                      ListTile(
                        title: Text('Phone: $_phone'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog('phone', _phone);
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: Text('Make Phone Public'),
                        value: _isPublicPhone,
                        onChanged: (value) {
                          setState(() {
                            _isPublicPhone = value;
                          });
                          _updateProfileField('isPublicPhone', value.toString());
                        },
                      ),
                      ListTile(
                        title: Text('Address: $_address'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog('address', _address);
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: Text('Make Address Public'),
                        value: _isPublicAddress,
                        onChanged: (value) {
                          setState(() {
                            _isPublicAddress = value;
                          });
                          _updateProfileField('isPublicAddress', value.toString());
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
