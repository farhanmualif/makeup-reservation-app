import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reservastion/profil.dart'; // Tambahkan import untuk Firebase Auth

class PaketPage extends StatefulWidget {
  const PaketPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaketPageState createState() => _PaketPageState();
}

class _PaketPageState extends State<PaketPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Inisialisasi instance Cloud Firestore
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Inisialisasi instance Firebase Auth

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
                        builder: (context) => const ProfilPage()));
              },
            ),
            ListTile(
              title: const Text('Histori Pemesanan'),
              onTap: () {
                // Navigasi ke halaman histori pemesanan
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
                final documents = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final data =
                        documents[index].data() as Map<String, dynamic>;
                    return _buildPaketCard(
                      data['nama'],
                      data['harga'],
                      data['gambar'],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaketCard(String nama, String harga, String gambar) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              gambar,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              nama,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              harga,
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
          ),
        ],
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
