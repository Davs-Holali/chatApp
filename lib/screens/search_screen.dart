// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../config.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppConfig.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Handle search logic
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Search Result 1'),
                    onTap: () {
                      // Handle search result tap
                    },
                  ),
                  // Add more search results here
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
