import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _user = FirebaseAuth.instance.currentUser;
  final _nomorHpController = TextEditingController();

  @override
  void dispose() {
    _nomorHpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _user?.displayName ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            // const Text(
            //   'Nomor HP',
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 8),
            // TextField(
            //   controller: _nomorHpController,
            //   decoration: const InputDecoration(
            //     hintText: 'Masukkan nomor HP',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
