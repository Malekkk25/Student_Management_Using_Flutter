import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'SubjectPage.dart';
import 'student_management.dart';

class SubjectPageDashboard extends StatefulWidget {
  @override
  _SubjectPageDashboardState createState() => _SubjectPageDashboardState();
}

class _SubjectPageDashboardState extends State<SubjectPageDashboard> {
  List<Map<String, dynamic>> classes = [];
  List<String> departments = ['INFO', 'GC'];
  String selectedDepartment = 'INFO';
  String selectedDepartmentPop = 'INFO';

  @override
  void initState() {
    super.initState();
    fetchClassesFromBackend(selectedDepartment);
  }

  Future<void> fetchClassesFromBackend(String department) async {
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:8082/classes/depart/$department'));

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

  Future<List<Matiere>> fetchSubjectsByClass(String className) async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2:8082/classes/matieres/$className'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((subject) => Matiere.fromJson(subject)).toList();
    } else {
      print(response.statusCode);
      throw Exception('Failed to load subjects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subject Page'),
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
                  return GestureDetector(
                    onTap: () {
                      // Navigate to SubjectsPage with selected class details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectPage(
                            classId: classes[index]['codClass'].toString(),
                            className: classes[index]['nomClass'] ?? 'N/A',
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(classes[index]['nomClass'] ?? 'N/A'),
                      subtitle: Text('ID: ${classes[index]['codClass'] ?? 'N/A'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to StudentsPage with selected class details
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentManagementScreen(
                                    classId: classes[index]['codClass'].toString(),
                                    className: classes[index]['nomClass'] ?? 'N/A',
                                    selectedDepartment: selectedDepartment,
                                  ),
                                ),
                              );
                            },
                            child: Text('Students'),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.update),
                            onPressed: () {
                              // Call the method to show the update dialog for the selected class
                              _showUpdateClassPopup(context, classes[index]);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Call the method to show the delete dialog for the selected class
                              _showDeleteClassPopup(
                                context,
                                classes[index]['codClass'].toString(),
                              );
                            },
                          ),
                        ],
                      ),
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

  void _showDeleteClassPopup(BuildContext context, String classId) {
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
  void _deleteClass(String? classId) async {

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
    String className = '';
    String numberOfStudents = '';
    String selectedDepartmentForPopup = departments.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Class'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Class Name'),
                    onChanged: (value) {
                      className = value;
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Number of Students'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      numberOfStudents = value;
                    },
                  ),
                  DropdownButton<String>(
                    value: selectedDepartmentForPopup,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDepartmentForPopup = newValue!;
                      });
                    },
                    items: departments.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
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
                    _createNewClass(
                      selectedDepartmentForPopup,
                      className,
                      numberOfStudents,
                    );

                    Navigator.of(context).pop();
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
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
        fetchClassesFromBackend(selectedDepartmentPop);
      } else {
        throw Exception('Failed to create a new class');
      }
    } catch (error) {
      print('Error creating a new class: $error');
    }
  }

  void _updateClass(
      String classId,
      String department,
      String updatedClassName,
      String updatedNumberOfStudents,
      ) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/classes/updateClass/$classId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'depart': department,
          'nomClass': updatedClassName,
          'nbreEtud': int.parse(updatedNumberOfStudents),
        }),
      );

      if (response.statusCode == 200) {
        fetchClassesFromBackend(selectedDepartmentPop);
      } else {
        print(response.statusCode);
        print(response.body);
        throw Exception('Failed to update the class');
      }
    } catch (error) {
      print('Error updating the class: $error');
    }
  }
}
