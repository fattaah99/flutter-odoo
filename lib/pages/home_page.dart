import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart'; // Import the SignInScreen
import 'calendar_time_off_screen.dart'; // Import the CalendarTimeOffScreen
import 'attendance_screen.dart'; // Import the

class HomePage extends StatefulWidget {
  final String token;
  final int employeeId;
  final String employeeName;

  HomePage({
    required this.token,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Employee> employee;

  @override
  void initState() {
    super.initState();
    employee = fetchEmployee();
  }

  Future<Employee> fetchEmployee() async {
    final url = '{{host}}/employee/${widget.employeeId}';
    print('Fetching employee data from: $url'); // Debug log: URL

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'x-api-key': 'odoo', // Use the provided JWT token
        },
      );

      print(
          'Response status code: ${response.statusCode}'); // Debug log: Status code
      print('Response body: ${response.body}'); // Debug log: Response body

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('Parsed JSON data: $jsonData'); // Debug log: Parsed JSON data

        return Employee.fromJson(jsonData);
      } else {
        throw Exception('Failed to load employee data');
      }
    } catch (error) {
      print('Error occurred: $error'); // Debug log: Error details
      throw error;
    }
  }

  Future<void> logout() async {
    final url = '{{host}}/auth/logout';
    print('Logging out from: $url'); // Debug log: URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'x-api-key': 'odoo'
        },
      );

      print(
          'Response status code: ${response.statusCode}'); // Debug log: Status code
      print('Response body: ${response.body}'); // Debug log: Response body

      if (response.statusCode == 200) {
        // Navigate to the login screen after successful logout
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SignInScreen()), // Use SignInScreen instead of LoginScreen
          (route) => false, // Removes all previous routes
        );
      } else {
        throw Exception('Failed to logout');
      }
    } catch (error) {
      print('Error occurred: $error'); // Debug log: Error details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                widget.employeeName, // Menampilkan nama pengguna
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //         "Home Page",
              //         style: TextStyle(
              //           fontSize: 24,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       Text(
              //         widget.employeeName,
              //         style: TextStyle(
              //           fontSize: 18,
              //           color: Colors.blue.shade900,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Profile Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black38,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage('assets/foto.jpg'),
                              ),
                              SizedBox(height: 16),
                              FutureBuilder<Employee>(
                                future: employee,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else if (!snapshot.hasData) {
                                    return Text('No data found');
                                  } else {
                                    final employeeData = snapshot.data!;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildProfileDetail(
                                            "Name", employeeData.name),
                                        _buildProfileDetail(
                                            "Work Email", employeeData.email),
                                        _buildProfileDetail("Work Phone",
                                            employeeData.phoneNumber),
                                        _buildProfileDetail(
                                            "Position", employeeData.position),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Buttons Section
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    _buildButton(
                        context, "Attendance", Icons.check_circle, null),
                    _buildButton(context, "Time Off", Icons.access_time, null),
                    _buildButton(
                        context, "Employees", Icons.group, EmployeesPage()),
                    _buildButton(context, "", null, null),
                    _buildButton(context, "", null, null),
                    _buildButton(context, "", null, null),
                    _buildButton(context, "", null, null),
                    _buildButton(context, "", null, null),
                    _buildButton(context, "", null, null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String label, IconData? icon, Widget? page) {
    return GestureDetector(
      onTap: () {
        if (label == "Time Off") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarTimeOffScreen(token: widget.token),
            ),
          );
        }
        if (label == "Attendance") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(token: widget.token),
            ),
          );
        } else if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Model Employee
class Employee {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String position;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.position,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      email: json['work_email'],
      phoneNumber: json['work_phone'],
      position: json['job_title'],
    );
  }
}

// Halaman Attendance
class AttendancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance")),
      body: Center(child: Text("Attendance Page")),
    );
  }
}

// Halaman Employees
class EmployeesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employees")),
      body: Center(child: Text("Employees Page")),
    );
  }
}
