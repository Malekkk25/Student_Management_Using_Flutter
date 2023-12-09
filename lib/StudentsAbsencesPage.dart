import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentAbsencesPage extends StatefulWidget {
  final int studentId;
  final String studentNom;
  final String studentPrenom;

  StudentAbsencesPage({
    required this.studentId,
    required this.studentNom,
    required this.studentPrenom,
  });

  @override
  _StudentAbsencesPageState createState() => _StudentAbsencesPageState();
}

class Matiere {
  final int codMatiere;
  final String nomMat;

  Matiere(this.codMatiere, this.nomMat);
}

class _StudentAbsencesPageState extends State<StudentAbsencesPage> {
  List<Map<String, dynamic>> absences = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> subjects = [];

  late String selectedStudent;
  late int selectedSubject = 0;

  late TextEditingController studentUpdateNameController;
  late TextEditingController studentUpdateLastNameController;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    selectedStudent = widget.studentId.toString();
    fetchAbsencesForStudent(widget.studentId);
    if (selectedSubject == null || !subjectExists(selectedSubject)) {
      selectedSubject =
          subjects.isNotEmpty ? subjects[0]['codMatiere'] as int : 0;
    }

    fetchSubjectsForStudent(widget.studentId);
    studentUpdateNameController = TextEditingController();
    studentUpdateLastNameController = TextEditingController();
  }

  Future<void> fetchAbsencesForStudent(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/absences/etud/$studentId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          absences = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load absences');
      }
    } catch (error) {
      print('Error fetching absences: $error');
    }
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/classes/etudiants'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (error) {
      print('Error fetching students: $error');
    }
  }

  Future<void> fetchSubjectsForStudent(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/classes/etudiants/subjects/$studentId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          subjects = List<Map<String, dynamic>>.from(data);
          if (selectedSubject == null || !subjectExists(selectedSubject)) {
            selectedSubject =
                subjects.isNotEmpty ? subjects[0]['codMatiere'] as int : 0;
          }
          print(data);
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (error) {
      print('Error fetching subjects: $error');
    }
  }

  bool subjectExists(int subjectId) {
    return subjects.any((element) => element['codMatiere'] as int == subjectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absences for Student'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dropdown for selecting a student
            DropdownButton<String>(
              value: selectedStudent,
              onChanged: (String? newValue) {
                print('Selected student id: $newValue');
                setState(() {
                  selectedStudent = newValue ?? '';
                  fetchAbsencesForStudent(int.parse(selectedStudent));
                  fetchSubjectsForStudent(int.parse(selectedStudent));
                });
              },
              items: students.map<DropdownMenuItem<String>>(
                (Map<String, dynamic> student) {
                  return DropdownMenuItem<String>(
                    value: student['id']
                        .toString(), // Use the 'id' as a unique value
                    child: Text('${student['nom']} ${student['prenom']}'),
                  );
                },
              ).toList(),
            ),

            SizedBox(height: 16),
            Text(
              'Absences for Student ID : $selectedStudent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: absences.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                          'Subject: ${absences[index]['matiere']['nomMat']}'),
                      subtitle:
                          Text('Charge Horaire: ${absences[index]['nha']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Handle update action here
                              _showUpdateAbsenceForm(context, index);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Handle delete action here
                              _showDeleteConfirmationDialog(
                                  context, absences[index]['idAbsence']);
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
          _showAddAbsenceForm(context);
        },
        tooltip: 'Add Absence',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> updateAbsence(String absenceId, double nha, DateTime? dateA,
      int selectedSubject, int selectedStudent) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/absences/updateAbs/$absenceId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "matiere": {"codMatiere": selectedSubject},
          "etudiant": {"id": selectedStudent},
          "dateA": dateA?.toIso8601String() ?? '',
          "nha": nha
        }),
      );
      if (response != null) {
        print('Response body: ${response.body}');
        print('Status code: ${response.statusCode}');
      }
      if (response.statusCode == 200) {
        fetchAbsencesForStudent(selectedStudent);
      } else {
        throw Exception('Failed to update the student');
      }
    } catch (error) {
      print('Error updating the student: $error');
    }
  }

  void _showUpdateAbsenceForm(BuildContext context, int index) {
    DateTime abs = DateTime.parse(absences[index]['dateA'] ?? '');
    double nha = (absences[index]['nha'] ?? 1).toDouble();
    int subjectId = absences[index]['matiere']['codMatiere'] ?? 0;

    print('abs: $abs');
    print('nha: $nha');
    print('subjectId: $subjectId');
    print(absences[index]['idAbsence'].toString());
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Absence',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Date picker
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: abs,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text('Select Date: ${selectedDate.toLocal()}'),
              ),
              SizedBox(height: 16),

              DropdownButton<num>(
                value: nha,
                onChanged: (num? newValue) {
                  setState(() {
                    nha = newValue?.toDouble() ?? 1;
                  });
                },
                items: [1, 2, 4, 6, 8]
                    .map<DropdownMenuItem<num>>(
                      (num value) => DropdownMenuItem<num>(
                        value: value,
                        child: Text('$value hours'),
                      ),
                    )
                    .toList(),
              ),

              SizedBox(height: 16),
              // Dropdown for Subjects
              DropdownButton<int>(
                value: subjectId,
                onChanged: (int? newValue) {
                  setState(() {
                    subjectId = newValue ?? 0;
                  });
                },
                items: subjects.map<DropdownMenuItem<int>>(
                  (Map<String, dynamic> subject) {
                    return DropdownMenuItem<int>(
                      value: subject['codMatiere'] as int,
                      child: Text('${subject['nomMat']}'),
                    );
                  },
                ).toList(),
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  updateAbsence(
                    absences[index]['idAbsence'].toString(),
                    nha,
                    selectedDate,
                    subjectId,
                    absences[index]['etudiant']['id'],
                  );

                  Navigator.of(context).pop();
                },
                child: Text('Update Absence'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int absenceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Absence'),
          content: Text('Are you sure you want to delete this absence?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAbsence(absenceId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAbsence(int absenceId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8082/absences/deleteAbsence/$absenceId'),
      );

      if (response.statusCode == 200) {
        fetchAbsencesForStudent(int.parse(selectedStudent));
      } else {
        throw Exception('Failed to delete absence');
      }
    } catch (error) {
      print('Error deleting absence: $error');
    }
  }

  void _showAddAbsenceForm(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    double selectedChargeHoraire = 1;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Absence',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Date picker
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text('Select Date: ${selectedDate.toLocal()}'),
              ),
              SizedBox(height: 16),

              DropdownButton<num>(
                value: selectedChargeHoraire,
                onChanged: (num? newValue) {
                  setState(() {
                    selectedChargeHoraire = newValue?.toDouble() ?? 1;
                  });
                },
                items: [1, 2, 4, 6, 8]
                    .map<DropdownMenuItem<num>>(
                      (num value) => DropdownMenuItem<num>(
                        value: value,
                        child: Text('$value hours'),
                      ),
                    )
                    .toList(),
              ),

              SizedBox(height: 16),
              // Dropdown for Subjects
              DropdownButton<int>(
                value: selectedSubject,
                onChanged: (int? newValue) {
                  setState(() {
                    selectedSubject = newValue ?? 0;
                  });
                },
                items: subjects.map<DropdownMenuItem<int>>(
                  (Map<String, dynamic> subject) {
                    return DropdownMenuItem<int>(
                      value: subject['codMatiere'] as int,
                      child: Text('${subject['nomMat']}'),
                    );
                  },
                ).toList(),
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final response = await http.post(
                    Uri.parse('http://10.0.2.2:8082/absences/add'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode({
                      "matiere": {"codMatiere": selectedSubject},
                      "etudiant": {"id": int.parse(selectedStudent)},
                      "dateA": selectedDate.toIso8601String(),
                      "nha": selectedChargeHoraire
                    }),
                  );

                  if (response.statusCode == 200) {
                    fetchAbsencesForStudent(int.parse(selectedStudent));
                    Navigator.pop(context);
                  } else {
                    print('Failed to add absence: ${response.statusCode}');
                  }
                },
                child: Text('Add Absence'),
              ),
            ],
          ),
        );
      },
    );
  }
}
