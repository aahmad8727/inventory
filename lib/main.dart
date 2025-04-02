import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InventoryHomePage(),
    );
  }
}

// Displays, Updates, Deletes Items
class InventoryHomePage extends StatelessWidget {
  const InventoryHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final collectionRef = FirebaseFirestore.instance.collection('product');

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Home Page')),
      body: StreamBuilder<QuerySnapshot>(
        // Displaying Inventory Items in Real-Time
        stream: collectionRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'No Name';
              final price = data['price']?.toString() ?? 'No Price';

              return ListTile(
                title: Text(name),
                subtitle: Text('Price: $price'),
                // Update item icon
                leading: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => UpdateItemScreen(
                              docId: doc.id,
                              currentName: name,
                              currentPrice: data['price']?.toString() ?? '',
                            ),
                      ),
                    );
                  },
                ),
                // Delete item icon
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    // 7. Deleting Inventory Items
                    await collectionRef.doc(doc.id).delete();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Adding New Inventory Items
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionRef = FirebaseFirestore.instance.collection('product');

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Add Item'),
              onPressed: () async {
                final name = _nameController.text.trim();
                final price = double.tryParse(_priceController.text) ?? 0.0;

                if (name.isNotEmpty) {
                  await collectionRef.add({'name': name, 'price': price});
                  Navigator.pop(context); // Go back to home
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// UpdateItemScreen: Form to Update Existing Items
class UpdateItemScreen extends StatefulWidget {
  final String docId;
  final String currentName;
  final String currentPrice;

  const UpdateItemScreen({
    Key? key,
    required this.docId,
    required this.currentName,
    required this.currentPrice,
  }) : super(key: key);

  @override
  _UpdateItemScreenState createState() => _UpdateItemScreenState();
}

class _UpdateItemScreenState extends State<UpdateItemScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _priceController = TextEditingController(text: widget.currentPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionRef = FirebaseFirestore.instance.collection('product');

    return Scaffold(
      appBar: AppBar(title: const Text('Update Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Update Item'),
              onPressed: () async {
                final newName = _nameController.text.trim();
                final newPrice = double.tryParse(_priceController.text) ?? 0.0;

                if (newName.isNotEmpty) {
                  // 6. Updating Inventory Items
                  await collectionRef.doc(widget.docId).update({
                    'name': newName,
                    'price': newPrice,
                  });
                  Navigator.pop(context); // Go back to home
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
