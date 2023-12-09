import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tp7v3/register.dart';

import 'dashboard.dart';
import 'user.dart';

class Login extends StatefulWidget {
  const Login() : super();

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String url = "http://10.0.2.2:8082/login";

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  Future<User> save(String email, String password) async {
    var res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}));
    print(res.body);
    if (res.statusCode == 200) {
      return User.fromMap(
        jsonDecode(res.body),
      );
    } else {
      throw Exception('Failed to login.');
    }
  }

  handleSignIn() async {
    if (_formKey.currentState == null) return;
    if (_formKey.currentState!.validate()) {
      try {
        User u = await save(_emailController.text, _passwordController.text);
        print(u.email);

        if (u != null) {
          // If the login was successful, navigate to the Home/Dashboard page.
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    Dashboard()), // Replace 'HomePage' with your actual home page widget.
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not log in with these credentials!',
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
        // Add an AppBar with the title "Login".
        title: Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Container(
                  height: 120.0,
                  width: 340.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      TextFormField(
                        controller: _emailController,
                        onChanged: (val) {},
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is empty';
                          }
                          return null;
                        },
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blueGrey.shade700,
                        ),
                        decoration: InputDecoration(
                          errorStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 120.0,
                  width: 340.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        onChanged: (val) {},
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is empty';
                          }
                          return null;
                        },
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blueGrey.shade700,
                        ),
                        decoration: InputDecoration(
                          errorStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 4,
                  color: Color.fromRGBO(255, 255, 255, 0.4),
                ),
                SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Register()));
                  },
                  child: Text(
                    'Do you want to sign up?',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleSignIn,
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
