// lib/screens/contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<DocumentSnapshot> _contacts = [];

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
    });
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: searchQuery)
        .where('email', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .get();
    setState(() {
      _contacts = usersSnapshot.docs;
      _isLoading = false;
    });
  }

  Future<void> _addContact(String contactId) async {
    final user = auth.currentUser;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final contactSnapshot = await userRef.collection('contacts').doc(contactId).get();

    if (!contactSnapshot.exists) {
      await userRef.collection('contacts').doc(contactId).set({
        'contactId': contactId,
        'addedAt': Timestamp.now(),
      });

      setState(() {
        _contacts.add(contactSnapshot);
      });
    }
  }

  void _startChat(String contactId) async {
    final user = auth.currentUser;
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user!.uid)
        .get();

    final existingChat = chatQuery.docs.firstWhere(
      (doc) {
        final participants = List<String>.from(doc['participants']);
        return participants.contains(contactId);
      },
      // orElse: () => null as QueryDocumentSnapshot<Map<String, dynamic>>?,
    );

    if (existingChat != null) {
      final chatId = existingChat.id;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(chatId: chatId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    } else {
      final newChatRef = FirebaseFirestore.instance.collection('chats').doc();
      await newChatRef.set({
        'participants': [user.uid, contactId],
        'lastMessage': '',
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(chatId: newChatRef.id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search Contacts',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
            _searchUsers();
          },
        ),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                var userData = _contacts[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData.containsKey('profileImageUrl')
                        ? NetworkImage(userData['profileImageUrl'])
                        : const AssetImage('assets/contact.png') as ImageProvider,
                  ),
                  title: Text(userData['email']),
                  subtitle: Text(userData['phone']),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      await _addContact(_contacts[index].id);
                      _startChat(_contacts[index].id);
                    },
                  ),
                  onTap: () async {
                    await _addContact(_contacts[index].id);
                    _startChat(_contacts[index].id);
                  },
                );
              },
            ),
    );
  }
}
