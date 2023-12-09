import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Matiere {
  final String nomMat;
  final int codMatiere;
  final String hours; // Separate fields for hours and minutes
  final String minutes;

  Matiere({
    required this.nomMat,
    required this.codMatiere,
    required this.hours,
    required this.minutes,
  });

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      nomMat: json['nomMat'],
      codMatiere: json['codMatiere'],
      hours: json['hours'],
      minutes: json['minutes'],
    );
  }
}

class SubjectPage extends StatefulWidget {
  final String classId;
  final String className;

  SubjectPage({required this.classId, required this.className});

  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  late Future<List<Matiere>> subjects;

  @override
  void initState() {
    super.initState();
    subjects = fetchSubjectsByClass(int.parse(widget.classId));
  }

  Future<List<Matiere>> fetchSubjectsByClass(int classCode) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8082/classes/matieres/$classCode'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((subject) => Matiere.fromJson(subject)).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  Future<void> addSubject(
      String subjectName, int? selectedHours, int? selectedMinutes) async {
    try {
      Duration? duration;

      // Check if both hours and minutes are provided
      if (selectedHours != null && selectedMinutes != null) {
        duration = Duration(hours: selectedHours, minutes: selectedMinutes);
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/classes/matieres/addMatiere'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nomMat': subjectName,
          'hours': selectedHours,
          'minutes': selectedMinutes,
          'classes': [
            {'codClass': widget.classId}
          ],
        }),
      );

      if (response.statusCode == 200) {
        // Refresh the page after adding a new subject
        setState(() {
          subjects = fetchSubjectsByClass(int.parse(widget.classId));
        });
      } else {
        print('Response Status Code: ${response.statusCode}');
        throw Exception('Failed to add a new subject');
      }
    } catch (error) {
      print('Error adding a new subject: $error');
    }
  }

  Future<void> updateSubject(
      int subjectId, String subjectName, Duration? selectedDuration) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:8082/classes/matieres/updateMatiere/$subjectId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nomMat': subjectName,
          'hours': selectedDuration?.inHours,
          'minutes': selectedDuration?.inMinutes.remainder(60),
        }),
      );

      if (response.statusCode == 200) {
        // Refresh the page after updating the subject
        setState(() {
          subjects = fetchSubjectsByClass(int.parse(widget.classId));
        });
      } else {
        throw Exception('Failed to update the subject');
      }
    } catch (error) {
      print('Error updating the subject: $error');
    }
  }

  Future<void> deleteSubject(int subjectId) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete this subject?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        final response = await http.delete(
          Uri.parse(
              'http://10.0.2.2:8082/classes/matieres/deleteMat/$subjectId'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 204) {
          // Refresh the page after deleting the subject
          setState(() {
            subjects = fetchSubjectsByClass(int.parse(widget.classId));
          });
        } else if (response.statusCode == 404) {
          print('Subject not found');
        } else {
          throw Exception('Failed to delete the subject');
        }
      }
    } catch (error) {
      print('Error deleting the subject: $error');
    }
  }

  // Declare your text editing controllers at the top of the class
  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController minutesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects for Class ${widget.className}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display subjects here using the 'subjects' list
            Expanded(
              child: FutureBuilder<List<Matiere>>(
                future: subjects,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Matiere> subjectList = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: subjectList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(subjectList[index].nomMat),
                          subtitle: Text(
                              'Duration: ${Duration(milliseconds: subjectList[index].codMatiere)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showUpdateSubjectPopup(
                                    context,
                                    subjectList[index].codMatiere,
                                  );
                                },
                                child: Text('Update'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle delete logic here
                                  deleteSubject(subjectList[index].codMatiere);
                                },
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.red,
                                ),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSubjectPopup(context);
        },
        tooltip: 'Add Subject',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showUpdateSubjectPopup(BuildContext context, int subjectId) async {
    try {
      // Fetch the data when the dialog is opened
      List<Matiere> subjectList = await subjects;

      // Find the subject by ID in the list
      Matiere subjectToUpdate =
          subjectList.firstWhere((subject) => subject.codMatiere == subjectId);

      // Set initial values for text fields
      subjectNameController.text = subjectToUpdate.nomMat;
      hoursController.text = subjectToUpdate.hours; // Set hours
      minutesController.text = subjectToUpdate.minutes; // Set minutes

      Duration selectedDuration =
          Duration(milliseconds: subjectToUpdate.codMatiere);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Update Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectNameController,
                  decoration: InputDecoration(labelText: 'Subject New Name'),
                ),
                SizedBox(height: 8),
                Text('Select Duration:'),
                ElevatedButton(
                  onPressed: () async {
                    final Duration? pickedDuration = await _showDurationPicker(
                      context: context,
                      initialTime: selectedDuration,
                    );

                    if (pickedDuration != null) {
                      setState(() {
                        selectedDuration = pickedDuration;
                        hoursController.text =
                            selectedDuration.inHours.toString();
                        minutesController.text =
                            selectedDuration.inMinutes.remainder(60).toString();
                      });
                    }
                  },
                  child: Text('Pick Duration'),
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
                  // Update the subject by calling the updateSubject function
                  updateSubject(
                    subjectId,
                    subjectNameController.text,
                    selectedDuration,
                  );
                  Navigator.of(context).pop();
                },
                child: Text('Update'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      print('Error fetching subjects: $error');
    }
  }

  Future<Duration?> _showDurationPicker({
    required BuildContext context,
    required Duration initialTime,
  }) async {
    int? selectedHours;
    int? selectedMinutes;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        selectedHours = int.tryParse(value) ?? 0;
                      },
                      decoration: InputDecoration(labelText: 'Hours'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        selectedMinutes = int.tryParse(value) ?? 0;
                      },
                      decoration: InputDecoration(labelText: 'Minutes'),
                    ),
                  ),
                ],
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
                Navigator.of(context).pop(Duration(
                  hours: selectedHours ?? 0,
                  minutes: selectedMinutes ?? 0,
                ));
              },
              child: Text('Select'),
            ),
          ],
        );
      },
    );

    if (selectedHours != null && selectedMinutes != null) {
      return Duration(hours: selectedHours!, minutes: selectedMinutes!);
    }

    return null;
  }

  void _showAddSubjectPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedHours;
        int? selectedMinutes;

        return AlertDialog(
          title: Text('Add New Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectNameController,
                decoration: InputDecoration(labelText: 'Subject Name'),
              ),
              SizedBox(height: 8),
              Text('Select Duration:'),
              ElevatedButton(
                onPressed: () async {
                  final Duration? pickedDuration = await _showDurationPicker(
                    context: context,
                    initialTime: Duration(milliseconds: 0),
                  );

                  if (pickedDuration != null) {
                    setState(() {
                      selectedHours = pickedDuration.inHours;
                      selectedMinutes = pickedDuration.inMinutes.remainder(60);
                    });
                  }
                },
                child: Text('Pick Duration'),
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
                addSubject(
                  subjectNameController.text,
                  selectedHours ?? 0,
                  selectedMinutes ?? 0,
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
}
