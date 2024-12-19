import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:reservastion/screen/ThankyouPage.dart';
import 'package:reservastion/screen/date_management.dart';
import 'package:reservastion/screen/forgot_password.dart';
import 'package:reservastion/screen/order_history.dart';
import 'package:reservastion/screen/order_in.dart';
import 'package:reservastion/screen/root_page.dart';
import 'package:reservastion/screen/admin_dashboard.dart';
import 'screen/signup.dart';
import 'screen/login.dart';
import 'screen/home.dart';
import 'screen/paket.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? "",
      appId: 'com.example.reservastion',
      messagingSenderId: '429999301527',
      projectId: 'reservation-47629',
      storageBucket: 'reservation-47629.appspot.com',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth App',
      initialRoute: '/', // Halaman awal adalah halaman Login
      routes: {
        '/': (context) => const RootPage(), // Rute untuk halaman Home
        '/login': (context) => const LoginScreen(), // Rute untuk halaman Login
        '/sign-up': (context) =>
            const SignUpPage(), // Rute untuk halaman SignUp
        '/paket': (context) => const PaketPage(),
        '/home': (context) => const HomePage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/success': (context) => const ThankYouPage(),
        '/order-history': (context) => OrderHistory(),
        '/order-in': (context) => const OrderIn(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/date-management': (context) => const DateManagement(),
      },
    );
  }
}
