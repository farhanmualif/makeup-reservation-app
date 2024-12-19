import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reservastion/screen/login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _usernameController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  var rool = "user";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[300],
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.05,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    _buildTitle(screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    _buildForm(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.03),
                    _buildSignUpButton(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.02),
                    _buildLoginLink(screenWidth),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIcon(double screenWidth) {
    return Icon(
      Icons.lock,
      size: screenWidth * 0.15,
      color: Colors.grey[600],
    );
  }

  Widget _buildTitle(double screenWidth) {
    return Text(
      'Let\'s create an account for you',
      style: TextStyle(fontSize: screenWidth * 0.05),
    );
  }

  Widget _buildForm(double screenWidth, double screenHeight) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextFormField(_usernameController, 'Username', screenHeight),
          _buildTextFormField(_fullnameController, 'Full Name', screenHeight),
          _buildTextFormField(_phoneController, 'Number Phone', screenHeight),
          _buildTextFormField(_emailController, 'Email', screenHeight),
          _buildTextFormField(_passwordController, 'Password', screenHeight,
              isPassword: true),
          _buildTextFormField(
              _confirmPasswordController, 'Confirm password', screenHeight,
              isPassword: true),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller, String hintText, double screenHeight,
      {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[600]!),
          ),
        ),
        validator: (value) => _validateField(value, hintText, isPassword),
      ),
    );
  }

  String? _validateField(String? value, String fieldName, bool isPassword) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }
    if (isPassword &&
        fieldName == 'Confirm password' &&
        value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Widget _buildSignUpButton(double screenWidth, double screenHeight) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(double screenWidth) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/login'),
      child: Text(
        'Already an account? Login',
        style: TextStyle(
          color: Colors.blue,
          fontSize: screenWidth * 0.04,
        ),
      ),
    );
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      signUp(
        _emailController.text,
        _passwordController.text,
        rool,
        _fullnameController.text,
        _phoneController.text,
      );
    }
  }

  void signUp(String email, String password, String rool, String fullname,
      String phone) async {
    try {
      setState(() {
        _isLoading = true;
      });
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        CollectionReference users =
            FirebaseFirestore.instance.collection('users');

        await users.doc(user.uid).set({
          'email': email,
          'rool': 'user',
          'fullname': fullname,
          'phone': phone,
          'uid': user.uid,
        });
        await user.updateDisplayName(_usernameController.text);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        _showSnackBar('Registration successful');
      } else {
        _showSnackBar('Registration failed: User is null');
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    if (e.code == 'weak-password') {
      _showSnackBar('The password provided is too weak');
    } else if (e.code == 'email-already-in-use') {
      _showSnackBar('The account already exists for that email');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
