import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Impor firebase_auth
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:reservastion/form_add_packet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/form_delete_packet.dart';
import 'package:reservastion/form_edit_packet.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Inisialisasi FirebaseAuth

  final List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    // _initializeFirebase();
    // _getProducts();
  }

  // Future<void> _initializeFirebase() async {
  //   await Firebase.initializeApp();
  // }

  // Tambahkan metode lain untuk menambah, mengedit, dan menghapus produk

  Future<void> _logout() async {
    await _auth.signOut(); // Logout dari FirebaseAuth
    Navigator.pushReplacementNamed(
        context, '/login'); // Navigasi ke halaman login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                _logout, // Panggil metode _logout saat tombol logout ditekan
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulir untuk menambah produk baru
          TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPaketForm(),
                    ));
              },
              child: const Text("Add packet")),
          // Daftar produk dari Firestore
          Expanded(
            child: FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('products_packet')
                  .get(),
              builder: (context, snapshot) {
                print(snapshot.data);

                // EROR
                // final document = snapshot.data!.docs;
                // .....

                return ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    Product product = _products[index];

                    // baru
                    // final data = document[index].data() as Map<String, dynamic>;
                    // final productID = document[index].id;
                    // ......

                    return ListTile(
                      leading: Image.network(product.imageUrl),
                      title: Text(product.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // Logika untuk mengedit produk
                              // baru.....
                              // final product = Product(
                              //   id: productID,
                              //   name: data['nama'],
                              //   price: data['harga'],
                              //   imageUrl: data['gambar'],
                              // );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        EditPaketForm(product: product)),
                              );
                              // .......
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Logika untuk menghapus produk
                              // baru.....
                              // showDialog(
                              //   context: context,
                              //   builder: (context) =>
                              //       DeletePaketDialog(productId: productID),
                              // );
                              // ......
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}
