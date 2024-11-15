class User {
  final String email;
  final String fullName;

  User({required this.email, required this.fullName});

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      email: data['email'] ?? '',
      fullName: data['fullname'] ?? '',
    );
  }
}