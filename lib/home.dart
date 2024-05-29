import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reservastion/order_history.dart';
import 'package:reservastion/profil.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                'Home',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
            ),
            Image.asset(
              'assets/images/mua.png',
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
