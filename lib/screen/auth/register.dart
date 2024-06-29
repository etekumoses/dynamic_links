import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamiclinksapp/services/dynamiclinks.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final DynamicLinksService _dynamicLinksService =
      DynamicLinksService(); // Initialize DynamicLinksService

  @override
  void initState() {
    super.initState();
    _initDynamicLinks(); // Initialize dynamic links handling on screen initialization
  }

  Future<void> _initDynamicLinks() async {
    String? projectId = await _dynamicLinksService.handleDynamicLinks(context);

    if (projectId != null) {
      await _registerUser(); // Simulated registration action
      Navigator.pushReplacementNamed(context, '/projects');
    }
  }

  Future<void> _registerUser() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create a UserModel object for the new user
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        displayName: _displayNameController.text.trim(),
        photoUrl: 'https://example.com/photo.jpg', // Placeholder for now
      );

      // Example: Store additional user data in Firestore
      await saveUserModelToFirestore(newUser);

      // Navigate to dashboard on successful registration
      Navigator.pushReplacementNamed(context, '/projects');
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> saveUserModelToFirestore(UserModel userModel) async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Convert the UserModel to a Map
      Map<String, dynamic> userData = userModel.toJson();

      // Set the document in the 'users' collection using the user's UID
      await firestore.collection('users').doc(userModel.uid).set(userData);

      print('User data saved to Firestore: ${userModel.toJson()}');
    } catch (e) {
      print('Error saving user data: $e');
      // Handle error appropriately, e.g., show error message to user
      throw Exception('Failed to save user data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                ),
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _registerUser(),
                child: Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
