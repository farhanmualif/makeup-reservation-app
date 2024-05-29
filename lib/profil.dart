import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nomorHpController = TextEditingController();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Dapatkan referensi ke database Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Dapatkan pengguna saat ini
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Dapatkan data profil pengguna berdasarkan ID akun
        DocumentSnapshot snapshot =
            await firestore.collection('users').doc(currentUser.uid).get();

        if (snapshot.exists) {
          // Konversi data snapshot menjadi Map<String, dynamic>
          Map<String, dynamic> profileData =
              snapshot.data() as Map<String, dynamic>;
          return profileData;
        } else {
          // Jika data tidak ditemukan, kembalikan Map kosong
          return {};
        }
      } else {
        // Jika pengguna saat ini tidak ada, kembalikan Map kosong
        return {};
      }
    } catch (e) {
      // Tangani kesalahan
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.hasData) {
          var profileData = snapshot.data!;
          print("cek profile $profileData");
          var fullName = profileData['fullname'] as String?;
          var email = profileData['email'] as String?;
          var phoneNumber = profileData['phone'] as String?;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Full Name'),
                    subtitle: Text(fullName!),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(email!),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(phoneNumber!),
                  ),
                ],
              ),
            ),
          );
        }

        return const Center(
          child: Text('No user profile data found'),
        );
      },
    );
  }
}
