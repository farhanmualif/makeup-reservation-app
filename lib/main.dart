import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'login.dart';
import 'home.dart';
import 'paket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: "AIzaSyAl2ydGodfysTnS36ZJrsb3-OcDHJWpAwU",
    appId: 'com.example.reservastion',
    messagingSenderId: '429999301527',
    projectId: 'reservation-47629',
    storageBucket: 'reservation-47629.appspot.com',
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth App',
      initialRoute: '/login', // Halaman awal adalah halaman Login
      routes: {
        '/': (context) => HomePage(), // Rute untuk halaman Home
        '/login': (context) => LoginScreen(), // Rute untuk halaman Login
        '/sign-up': (context) => SignUpPage(), // Rute untuk halaman SignUp
        '/paket': (context) => PaketPage(), // Rute untuk halaman PaketPage
      },
    );
  }
}
