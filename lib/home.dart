import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  List<Map<String, dynamic>> classes = [];
  Map<String, dynamic>? selectedClass;
  @override
  void initState() {
    super.initState();
    // Fetch classes from the backend API and update the 'classes' list
    fetchClassesFromBackend();
  }

  // Method to fetch classes from the backend
  Future<void> fetchClassesFromBackend() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8082/classes'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('_embedded') && data['_embedded'] != null) {
          List<dynamic> classesData = data['_embedded']['classes'];
          setState(() {
            classes = List<Map<String, dynamic>>.from(classesData);
          });
        } else {
          throw Exception('No classes found');
        }
      } else {
        throw Exception('Failed to load classes');
      }
    } catch (error) {
      print('Error fetching classes: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<Map<String, dynamic>>(
              value: selectedClass,
              hint: Text('Select a class'),
              items: classes.map<DropdownMenuItem<Map<String, dynamic>>>((classData) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: classData,
                  child: Text(classData['nomClass'].toString()),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? classData) {
                setState(() {
                  selectedClass = classData;
                });
                if (classData != null) {
                  print(classData['nomClass']);
                }
                fetchClassesFromBackend(); // Fetch classes when the DropdownButton is changed
              },
            ),
            // Other widgets
          ],
        ),
      ),
    );
  }
}