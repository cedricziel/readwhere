import 'package:flutter/material.dart';

/// The catalogs screen for browsing OPDS catalogs and online book sources.
///
/// This screen allows users to discover and download books from
/// various OPDS catalogs and online sources.
class CatalogsScreen extends StatelessWidget {
  const CatalogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogs'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Catalogs Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Browse online book catalogs',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add catalog functionality
        },
        tooltip: 'Add Catalog',
        child: const Icon(Icons.add),
      ),
    );
  }
}
