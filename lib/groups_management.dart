import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupsManagementScreen extends StatefulWidget {
  @override
  _GroupsManagementScreenState createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends State<GroupsManagementScreen> {
  List<Map<String, dynamic>> classes = [];
  List<String> departments = ['INFO', 'GC']; // Your list of departments
  String selectedDepartment = 'INFO'; // Default selected department

  @override
  void initState() {
    super.initState();
    fetchClassesFromBackend(selectedDepartment);
  }

  Future<void> fetchClassesFromBackend(String department) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8082/classes/depart/$department'));
      print('Server Response: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            classes = List<Map<String, dynamic>>.from(data);
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
        title: Text('Classes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedDepartment,
              onChanged: (String? newValue) async {
                setState(() {
                  selectedDepartment = newValue!;
                });

                // Fetch classes for the selected department
                await fetchClassesFromBackend(selectedDepartment);
              },
              items: departments.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            SizedBox(height: 20),
            Text(
              'Classes for $selectedDepartment department:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(classes[index]['nomClass'] ?? 'N/A'),
                    subtitle: Text('ID: ${classes[index]['codClass'] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showUpdateClassPopup(context, classes[index]);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmation(context, classes[index]['codClass'].toString());
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateClassPopup(context);
        },
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String classId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Class'),
          content: Text('Are you sure you want to delete this class?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteClass(classId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _deleteClass(String classId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8082/classes/deleteClass/$classId'),
      );

      if (response.statusCode == 200) {
        // Class deleted successfully, refresh the class list
        fetchClassesFromBackend(selectedDepartment);
      } else {
        throw Exception('Failed to delete the class');
      }
    } catch (error) {
      print('Error deleting the class: $error');
    }
  }



  void _showCreateClassPopup(BuildContext context) {
    TextEditingController classNameController = TextEditingController();
    String selectedDepartment = departments[0];
    TextEditingController numberOfStudentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AlertDialog(
                  title: Text('Create New Class'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: selectedDepartment,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDepartment = newValue;
                            });
                          }
                        },
                        items: departments.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      TextField(
                        controller: classNameController,
                        decoration: InputDecoration(labelText: 'Class Name'),
                      ),
                      TextField(
                        controller: numberOfStudentsController,
                        decoration: InputDecoration(labelText: 'Number of Students'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _createNewClass(
                          selectedDepartment,
                          classNameController.text,
                          numberOfStudentsController.text,
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text('Create'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  void _createNewClass(
      String department,
      String className,
      String numberOfStudents,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/classes/put'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'depart': department,
          'nomClass': className,
          'nbreEtud': numberOfStudents,
        }),
      );

      if (response.statusCode == 201) {
        // Class created successfully, refresh the class list
        fetchClassesFromBackend(selectedDepartment);
      } else {
        throw Exception('Failed to create a new class');
      }
    } catch (error) {
      print('Error creating a new class: $error');
    }
  }

  void _showUpdateClassPopup(BuildContext context, Map<String, dynamic> classDetails) {
    String updatedClassName = classDetails['nomClass'].toString();
    String updatedNumberOfStudents = classDetails['nbreEtud'].toString();
    String updatedDepartment = classDetails['depart'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Department'),
                controller: TextEditingController(text: updatedDepartment),
                onChanged: (value) {
                  updatedDepartment = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Class Name'),
                controller: TextEditingController(text: updatedClassName),
                onChanged: (value) {
                  updatedClassName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Number of Students'),
                controller: TextEditingController(text: updatedNumberOfStudents),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  updatedNumberOfStudents = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateClass(
                  classDetails['codClass'].toString(),
                  updatedDepartment,
                  updatedClassName,
                  updatedNumberOfStudents,
                );

                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateClass(
      String classId,
      String department,
      String className,
      String numberOfStudents,
      ) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/classes/updateClass/$classId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'depart': department,
          'nomClass': className,
          'nbreEtud': numberOfStudents,
        }),
      );

      if (response.statusCode == 200) {
        // Class updated successfully, refresh the class list
        fetchClassesFromBackend(selectedDepartment);
      } else {
        throw Exception('Failed to update the class');
      }
    } catch (error) {
      print('Error updating the class: $error');
    }
  }
}
