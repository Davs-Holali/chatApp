// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import 'profile_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> messageStream;
  String? contactName;
  String? contactProfileImageUrl;
  String? contactId;

  @override
  void initState() {
    super.initState();
    messageStream = firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
    _getContactInfo();
  }

  void _getContactInfo() async {
    DocumentSnapshot chatDoc = await firestore.collection('chats').doc(widget.chatId).get();
    List participants = chatDoc['participants'];
    contactId = participants.firstWhere((id) => id != auth.currentUser!.uid);
    DocumentSnapshot userDoc = await firestore.collection('users').doc(contactId).get();
    var userData = userDoc.data() as Map<String, dynamic>;
    setState(() {
      contactName = '${userData['firstName']} ${userData['lastName']}';
      contactProfileImageUrl = userData.containsKey('profileImageUrl') ? userData['profileImageUrl'] : null;
    });
  }

  void sendMessage() async {
    if (messageController.text.isNotEmpty
    ) {
      await firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': messageController.text,
        'createdAt': Timestamp.now(),
        'userId': auth.currentUser!.uid,
      });
      await firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageController.text,
      });
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetailsScreen(userId: contactId!),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: contactProfileImageUrl != null
                    ? NetworkImage(contactProfileImageUrl!)
                    : const AssetImage('assets/profile.png') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Text(contactName ?? 'Chat'),
            ],
          ),
        ),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((doc) {
                    bool isMe = doc['userId'] == auth.currentUser!.uid;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              backgroundImage: contactProfileImageUrl != null
                                  ? NetworkImage(contactProfileImageUrl!)
                                  : const AssetImage('assets/profile.png') as ImageProvider,
                            ),
                          if (!isMe)
                            const SizedBox(width: 10),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.green[200] : Colors.white,
                                borderRadius: isMe
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                      )
                                    : const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['text'],
                                    style: TextStyle(color: isMe ? Colors.black : Colors.black),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    doc['createdAt'].toDate().toString().substring(11, 16),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe)
                            const SizedBox(width: 10),
                          if (isMe)
                            CircleAvatar(
                              backgroundImage: const AssetImage('assets/contact.png'),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
