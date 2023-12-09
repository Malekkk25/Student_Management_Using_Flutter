import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'StudentsAbsencesPage.dart';

class StudentManagementScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String selectedDepartment;

  StudentManagementScreen({
    required this.classId,
    required this.className,
    required this.selectedDepartment,
  });

  @override
  _StudentManagementScreenState createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Map<String, dynamic>> students = [];
  late String selectedDepartment;
  late String selectedClass;
  List<Map<String, dynamic>> classes = [];
  List<String> departments = ['INFO', 'GC']; // Add your department options here

  @override
  void initState() {
    super.initState();
    selectedDepartment = widget.selectedDepartment;
    selectedClass = widget.classId;
    if (selectedDepartment.isEmpty) {
      selectedDepartment = 'INFO';
    }
    if (selectedClass.isEmpty) {
      selectedClass = '1';
    }
    fetchClassesForDepartment(selectedDepartment);
  }

  void _navigateToAbsencesPage(
      int studentId, String studentNom, String studentPrenom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAbsencesPage(
            studentId: studentId,
            studentNom: studentNom,
            studentPrenom: studentPrenom),
      ),
    );
  }

  bool classExists(String classId) {
    return classes.any((element) => element['codClass'].toString() == classId);
  }

  Future<void> fetchClassesForDepartment(String department) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/classes/depart/$department'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            classes = List<Map<String, dynamic>>.from(data);
            if (selectedClass.isEmpty || !classExists(selectedClass)) {
              selectedClass =
                  classes.isNotEmpty ? classes[0]['codClass'].toString() : '';
            }
          });
          fetchStudentsForClass(selectedClass);
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

  Future<void> fetchStudentsForClass(String classId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/classes/$classId/etudiants'),
      );

      if (response.statusCode == 200) {
        dynamic data = json.decode(response.body);
        print('Response Data: $data');

        if (data.containsKey('_embedded') &&
            data['_embedded'] is Map<String, dynamic>) {
          dynamic embeddedData = data['_embedded'];
          if (embeddedData.containsKey('etudiants') &&
              embeddedData['etudiants'] is List) {
            setState(() {
              students =
                  List<Map<String, dynamic>>.from(embeddedData['etudiants']);
            });
          } else {
            throw Exception(
                'Invalid data format: expected List inside _embedded, but received ${embeddedData['etudiants'].runtimeType}');
          }
        } else {
          throw Exception(
              'Invalid data format: expected _embedded object, but received ${data['_embedded'].runtimeType}');
        }
      } else {
        throw Exception(
            'Failed to load students. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching students: $error');
    }
  }

  Future<void> addStudent(
    String studentName,
    String lastName,
    DateTime? selectedDate,
    String selectedDepartment,
    String selectedClass,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/classes/etudiants/addStudent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "nom": studentName,
          "prenom": lastName,
          "dateNais": selectedDate?.toIso8601String() ?? '',
          "formation": {"id": 1},
          "classe": {
            "codClass": selectedClass,
          }
        }),
      );

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        fetchStudentsForClass(selectedClass);
      } else {
        print(studentName);
        print(lastName);
        print(selectedDate);
        print(selectedDepartment);
        print(selectedClass);
        throw Exception('Failed to add a new student');
      }
    } catch (error) {
      print('Error adding a new student: $error');
    }
  }

  Future<void> updateStudent(
    int studentId,
    String studentName,
    String lastName,
    DateTime? dateOfBirth,
    String selectedClass,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:8082/classes/etudiants/updateStudent/$studentId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nom': studentName,
          'prenom': lastName,
          'dateNais':
              dateOfBirth?.toIso8601String() ?? '', // Format date of birth
        }),
      );

      if (response.statusCode == 200) {
        fetchStudentsForClass(selectedClass);
      } else {
        throw Exception('Failed to update the student');
      }
    } catch (error) {
      print('Error updating the student: $error');
    }
  }

  Future<void> deleteStudent(int studentId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'http://10.0.2.2:8082/classes/etudiants/deleteStudent/$studentId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        fetchStudentsForClass(selectedClass);
      } else if (response.statusCode == 404) {
        print('Student not found');
      } else {
        print(response.statusCode);
        throw Exception('Failed to delete the student');
      }
    } catch (error) {
      print('Error deleting the student: $error');
    }
  }

  DropdownButton<String> buildClassDropdown() {
    return DropdownButton<String>(
      value: selectedClass,
      onChanged: (String? newValue) {
        setState(() {
          selectedClass = newValue ?? '';
          fetchStudentsForClass(selectedClass);
        });
      },
      items:
          classes.map<DropdownMenuItem<String>>((Map<String, dynamic> value) {
        return DropdownMenuItem<String>(
          value: value['codClass'].toString(),
          child: Text(value['nomClass'].toString()),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students for ${widget.className}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dropdown for Departments
            DropdownButton<String>(
              value: selectedDepartment,
              onChanged: (String? newValue) {
                setState(() {
                  selectedDepartment = newValue ?? 'INFO';
                  fetchClassesForDepartment(selectedDepartment);
                });
              },
              items: departments.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            // Dropdown for Classes
            buildClassDropdown(),
            // Display students here using the 'students' list
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(students[index]['nom'] ?? 'N/A'),
                    subtitle: Text('ID: ${students[index]['id'] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showUpdateStudentPopup(context, index);
                          },
                          child: Text('Update'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            deleteStudent(students[index]['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                          ),
                          child: Text('Delete'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _navigateToAbsencesPage(
                                students[index]['id'],
                                students[index]['nom'],
                                students[index]['prenom']);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                          ),
                          child: Text('Absences'),
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
          _showAddStudentPopup(context);
        },
        tooltip: 'Add Student',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showUpdateStudentPopup(BuildContext context, int index) {
    DateTime? selectedDate;

    // Fetch the data of the selected student
    String initialName = students[index]['nom'] ?? '';
    String initialLastName = students[index]['prenom'] ?? '';
    // DateTime initialDateOfBirth = ... // Fetch the date of birth from students[index]

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Student'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: studentUpdateNameController
                      ..text = initialName, // Set the initial value
                    decoration: InputDecoration(labelText: 'Student New Name'),
                  ),
                  TextField(
                    controller: studentUpdateLastNameController
                      ..text = initialLastName, // Set the initial value
                    decoration:
                        InputDecoration(labelText: 'Student New Last Name'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text(selectedDate != null
                        ? 'Date of Birth: ${selectedDate!.toLocal()}'
                        : 'Select Date of Birth'),
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
                    updateStudent(
                      students[index]['id'],
                      studentUpdateNameController.text,
                      studentUpdateLastNameController.text,
                      selectedDate,
                      selectedClass,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddStudentPopup(BuildContext context) {
    TextEditingController studentNameController = TextEditingController();
    TextEditingController studentLastNameController = TextEditingController();
    DateTime? selectedDate; // Variable to store the selected date

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(selectedDate != null
                    ? 'Date: ${selectedDate!.toLocal()}'
                    : 'Select Date'),
              ),
              SizedBox(height: 10),
              // Student Name
              TextField(
                controller: studentNameController,
                decoration: InputDecoration(labelText: 'Student Name'),
              ),
              SizedBox(height: 10),
              // Student Last Name
              TextField(
                controller: studentLastNameController,
                decoration: InputDecoration(labelText: 'Student Last Name'),
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
                addStudent(
                  studentNameController.text,
                  studentLastNameController.text,
                  selectedDate,
                  selectedDepartment,
                  selectedClass,
                );
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLastNameController =
      TextEditingController();
  final TextEditingController studentUpdateNameController =
      TextEditingController();
  final TextEditingController studentUpdateLastNameController =
      TextEditingController();
}
