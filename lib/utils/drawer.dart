// lib/widgets/drawer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  File? myProfileImage;

  @override
  void initState() {
    super.initState();
    _loadMyProfileImage();
  }

  Future<void> _loadMyProfileImage() async {
    final user = auth.currentUser;
    final directory = await getApplicationDocumentsDirectory();
    final profileImagePath = path.join(directory.path, '${user!.uid}_profile.jpg');
    final profileImageFile = File(profileImagePath);
    if (await profileImageFile.exists()) {
      setState(() {
        myProfileImage = profileImageFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Loading...');
                }
                var userData = snapshot.data!;
                return Text('${userData['firstName']} ${userData['lastName']}');
              },
            ),
            accountEmail: Text(user!.email!),
            currentAccountPicture: CircleAvatar(
              backgroundImage: myProfileImage != null
                  ? FileImage(myProfileImage!)
                  : const AssetImage('assets/profile.png') as ImageProvider,
            ),
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
