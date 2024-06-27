// lib/screens/verification_screen.dart
import 'package:flutter/material.dart';
import '../config.dart';

class VerificationScreen extends StatelessWidget {
  final TextEditingController codeController = TextEditingController();

  VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Verification Code'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle code verification logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
