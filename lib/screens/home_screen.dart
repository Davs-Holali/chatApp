// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../config.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  File? profileImage;

  static const List<Widget> _widgetOptions = <Widget>[
    ChatsTab(),
    ContactsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    final directory = await getApplicationDocumentsDirectory();
    final profileImagePath =
        path.join(directory.path, '${user!.uid}_profile.jpg');
    final profileImageFile = File(profileImagePath);
    if (await profileImageFile.exists()) {
      setState(() {
        profileImage = profileImageFile;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChҵtAPP',
          style: TextStyle(
            color: AppConfig.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 30.0,
          ),
        ),
        backgroundColor: AppConfig.primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        iconTheme: const IconThemeData(color: AppConfig.iconColor),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppConfig.primaryColor,
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.hasError) {
                    return const Center(child: Text('Error loading profile'));
                  }
                  var userData = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                            : const AssetImage('assets/profile.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${userData['firstName']} ${userData['lastName']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userData['email'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.home,
                color: AppConfig.primaryColor,
              ),
              title: const Text(
                'Home',
                style: TextStyle(
                  color: AppConfig.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: AppConfig.primaryColor,
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: AppConfig.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: AppConfig.primaryColor,
            icon: Icon(
              Icons.chat,
              color: AppConfig.iconColor,
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            backgroundColor: AppConfig.primaryColor,
            icon: Icon(
              Icons.contacts,
              color: AppConfig.iconColor,
            ),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            backgroundColor: AppConfig.primaryColor,
            icon: Icon(
              Icons.person,
              color: AppConfig.iconColor,
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            backgroundColor: AppConfig.primaryColor,
            icon: Icon(
              Icons.settings,
              color: AppConfig.iconColor,
            ),
            label: 'Settings',
          ),
        ],
        showUnselectedLabels: true,
        enableFeedback: true,
        selectedLabelStyle: const TextStyle(
          color: Color.fromARGB(255, 231, 224, 222),
        ),
        unselectedLabelStyle: const TextStyle(
          color: Color.fromARGB(255, 72, 24, 3),
        ),
        currentIndex: _selectedIndex,
        selectedItemColor: AppConfig.textColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ChatsTab extends StatelessWidget {
  const ChatsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: auth.currentUser!.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              String lastMessage = doc['lastMessage'];
              List participants = doc['participants'];
              String contactId =
                  participants.firstWhere((id) => id != auth.currentUser!.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(contactId)
                    .get(),
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  var userData = userSnapshot.data!;
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundImage: AssetImage('assets/contact.png'),
                    ),
                    title: Text(
                      '${userData['firstName']} ${userData['lastName']}',
                      style: const TextStyle(color: AppConfig.primaryColor),
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: const TextStyle(color: AppConfig.accentColor),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: doc.id),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
