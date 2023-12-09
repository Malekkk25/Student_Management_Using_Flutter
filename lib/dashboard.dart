import 'package:flutter/material.dart';
import 'package:tp7v3/student_management.dart';

import 'DepartmentPage.dart';
import 'SubjectPageDashboard.dart';
import 'groups_management.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Manage Groups'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupsManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.school),
              title: Text('Manage Students'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentManagementScreen(
                      classId: '', // Provide a default or empty value
                      className: '',
                      selectedDepartment: '', // Add this line
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.business),
              title: Text('Manage Departments'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Manage Subjects'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectPageDashboard(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.close),
              title: Text('Close'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Dashboard Content'),
      ),
    );
  }
}
