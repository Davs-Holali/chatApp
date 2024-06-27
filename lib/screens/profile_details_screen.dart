// lib/screens/profile_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final String userId;
  const ProfileDetailsScreen({Key? key, required this.userId}) : super(key: key);

  Future<Map<String, dynamic>> _getUserProfile() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('User not found'));
          }
          var userData = snapshot.data!;

          bool isPublicPhone = userData['isPublicPhone'] ?? false;
          bool isPublicAddress = userData['isPublicAddress'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: userData.containsKey('profileImageUrl')
                            ? NetworkImage(userData['profileImageUrl'])
                            : const AssetImage('assets/profile.png') as ImageProvider,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: AppBar(
                        title: const Text(''),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${userData['firstName']} ${userData['lastName']}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(userData['email'], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                if (isPublicPhone)
                  Text(userData['phone'], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                if (isPublicAddress)
                  Text(userData['address'], style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
