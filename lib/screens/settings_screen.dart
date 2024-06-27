// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Handle account settings
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Handle notification settings
            },
          ),
          ListTile(
            title: const Text('Privacy'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Handle privacy settings
            },
          ),
          ListTile(
            title: const Text('Help'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Handle help settings
            },
          ),
        ],
      ),
    );
  }
}
