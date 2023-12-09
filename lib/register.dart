import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'user.dart';

class Register extends StatefulWidget {
  const Register() : super();

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String url = "http://10.0.2.2:8082/register";
  String? emailError; // Store the email error message.

  Future<User> register(String email, String password) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    print(res.body);
    if (res.statusCode == 200) {
      return User.fromMap(
        jsonDecode(res.body),
      );
    } else {
      throw Exception('Failed to register');
    }
  }

  void handleRegister() async {
    if (_formKey.currentState == null) return;
    if (_formKey.currentState!.validate()) {
      try {
        User u =
        await register(_emailController.text, _passwordController.text);
        print(u);
        // Navigate back to the login page.
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not register with these credentials!',
              style: TextStyle(fontSize: 16.0),
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // Email Field
                Column(
                  children: [
                    Container(
                      height: 120.0,
                      width: 340.0,
                      child: TextFormField(
                        controller: _emailController,
                        onChanged: (val) {
                          // Handle email input changes.
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        style: TextStyle(
                            fontSize: 20, color: Colors.blueGrey.shade700),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorStyle:
                          TextStyle(fontSize: 20, color: Colors.black),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (emailError != null)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          emailError!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                // Password Field
                Container(
                  height: 120.0,
                  width: 340.0,
                  child: TextFormField(
                    controller: _passwordController,
                    onChanged: (val) {
                      // Handle password input changes.
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is empty';
                      }
                      return null;
                    },
                    style: TextStyle(
                        fontSize: 20, color: Colors.blueGrey.shade700),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorStyle: TextStyle(fontSize: 20, color: Colors.black),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Container(
                  height: 4,
                  color: Color.fromRGBO(255, 255, 255, 0.4),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to the login page.
                    Navigator.pop(context);
                  },
                  child: Text('Already have an account? Log in'),
                ),
                ElevatedButton(
                  onPressed: handleRegister,
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
