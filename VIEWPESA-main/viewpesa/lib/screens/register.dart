import 'package:flutter/material.dart';
import '../database/dbhelper.dart';
import '../models/user_models.dart';
import 'package:path/path.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Added
  final DBHelper _dbHelper = DBHelper();

  // Added dispose method to prevent memory leaks
  @override
  void dispose() {
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _passwordController.dispose(); // Added
    super.dispose();
  }

  // Function to hash the password
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  Future<void> _register() async {
    final String username = _usernameController.text.trim();
    final String phoneNumber = _phoneController.text.trim();
    final String password =
    _passwordController.text.trim(); // Get password.
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty ||
        phoneNumber.isEmpty ||
        password.isEmpty || //check password
        confirmPassword.isEmpty) {
      _showSnackBar("Please fill in all fields.");
      return; // Stop registration if any field is empty
    }

    if (password !=
        confirmPassword) { // Check password match.
      _showSnackBar("Passwords do not match");
      return;
    }

    String hashedPassword =
    _hashPassword(password); // Hash the password using bcrypt

    final user = UserModel(
      username: username,
      phoneNumber: phoneNumber,
      password:
      hashedPassword,
      imagePath: ''// Store the hashed password.
    );

    try {
      await _dbHelper.insertUser(user);
      // Store user ID in shared preferences for later use (e.g., profile page).
      final prefs = await SharedPreferences.getInstance();
      final registeredUser =
      await _dbHelper.getUser(phoneNumber); // Use getUser
      if (registeredUser != null) {
        await prefs.setInt('userId', registeredUser.id!);
      }

      Navigator.pushReplacementNamed(
          context as BuildContext, '/home'); // Or any other route
    } catch (e) {
      _showSnackBar("Error registering user: ${e.toString()}"); // Show the error
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.greenAccent[700],
      ),
      body:  GestureDetector(
      onTap: () {
      FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
      },
    child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "VIEWPESA",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent[700],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Register",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 60),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                ),
                child: Text("Register"),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}