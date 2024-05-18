import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reservastion/screen/admin_dashboard.dart';
import 'login.dart';
import 'home.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  Future<String?> checkRoleUser(String id) async {
    try {
      var findUser =
          await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (findUser.exists) {
        return findUser.get("rool");
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data == null) {
            // User is not authenticated
            return const LoginScreen();
          } else {
            return FutureBuilder<String?>(
              future: checkRoleUser(snapshot.data!.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.done) {
                  if (roleSnapshot.data == "admin") {
                    return const AdminDashboard();
                  } else {
                    return const HomePage();
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          }
        } else {
          // Handling other connection states (e.g., waiting, error)
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
