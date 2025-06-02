import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reservastion/screen/order_history.dart';
import 'package:reservastion/screen/profil.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Stream<int> getAcceptedOrdersCount() {
    return FirebaseFirestore.instance
        .collection('order')
        .where('UserUid', isEqualTo: currentUser?.uid)
        .where('Status', isEqualTo: 'ACCEPT')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                        builder: (context) => const ProfilePage()));
              },
            ),
            StreamBuilder<int>(
              stream: getAcceptedOrdersCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return ListTile(
                  title: Row(
                    children: [
                      const Text('Histori Pemesanan'),
                      if (count > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => OrderHistory()));
                  },
                );
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
                'Home',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
            ),
            Image.asset(
              'assets/images/logotm.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300.0,
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Selamat datang di Tanti MakeUp Studio,',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
            ),
            // const SizedBox(
            //   height: 1,
            // ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Berdiri Sejak Tahun 2016, MUA Kami Telah Memiliki Banyak Pengalaman Dalam Bidang Merias Wajah Jadi Jangan Khawatir, Terdapat Beberapa Pilihan Jasa MakeUp Dari Kami.',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Yuuukkk, Pilih Paket MakeUp!!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman paket.dart
                  Navigator.pushNamed(context, '/paket');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Warna latar belakang tombol
                  foregroundColor: Colors.white, // Warna teks tombol
                  minimumSize: const Size(100, 51), // Ukuran tombol
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Bentuk tombol
                  ),
                ),
                child: const Text(
                  'PILIH PAKET',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
