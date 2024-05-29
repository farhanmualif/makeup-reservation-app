import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reservastion/detail_paket.dart';
import 'package:reservastion/order_history.dart';
import 'package:reservastion/profil.dart'; // Tambahkan import untuk Firebase Auth
// Tambahkan baris ini

class PaketPage extends StatefulWidget {
  const PaketPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaketPageState createState() => _PaketPageState();
}

class _PaketPageState extends State<PaketPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore
      .instance; // Inisialisasi instance Cloud Firestore// Inisialisasi instance Firebase Auth

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('TANTI MAKEUP STUDIO'),
        backgroundColor: Colors.grey[300],
        elevation: 0.5,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey,
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Profil'),
              onTap: () {
                // Navigasi ke halaman profil
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Histori Pemesanan'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => OrderHistory()));
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Home / Paket',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Paket MakeUp',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('paket_makeup').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final documents = snapshot.data!.docs;

                return Container(
                  margin: const EdgeInsets.only(left: 20, right: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final documentId = documents[index].id;
                      Map<String, dynamic> data =
                          documents[index].data() as Map<String, dynamic>;
                      String nama = data['Name'];
                      String harga = data['Price'];
                      String gambar = data['Image'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPaket(paketId: documentId),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.grey[300],
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            child: Column(
                              children: [
                                Image.network(
                                  gambar,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("IDR. $harga"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk logout
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigasi ke halaman login setelah logout berhasil
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Tangani error logout jika ada
      print('Logout error: $e');
    }
  }
}
