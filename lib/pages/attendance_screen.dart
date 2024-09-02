import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AttendanceScreen extends StatefulWidget {
  final String token;

  AttendanceScreen(
      {required this.token}); // Perbaiki nama konstruktor menjadi sesuai dengan nama kelas
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String employeeName = '';
  String checkInTime = 'Not Checked In';
  String checkOutTime = 'Not Checked Out';
  String workedHours = '0:00';

  bool _isLoading = false;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    final response = await http.get(
      Uri.parse('{{host}}/attendance/by-employee-date'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${widget.token}',
        'x-api-key': 'odoo', // Replace with your JWT token
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        setState(() {
          employeeName = data[0]['employee']?['name']?.toString() ??
              'Unknown'; // Replace with proper employee name handling
          checkInTime = DateFormat('HH:mm:ss')
              .format(DateTime.parse(data[0]['check_in']));
          checkOutTime = data[0]['check_out'] != null
              ? DateFormat('HH:mm:ss')
                  .format(DateTime.parse(data[0]['check_out']))
              : 'Not Checked Out';
          workedHours = data[0]['worked_hours'].toString();
        });
      }
    } else {
      print('Failed to load attendance data');
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await _determinePosition();
      String address =
          await _getAddressFromLatLng(position.latitude, position.longitude);
      String dateTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final response = await http.post(
        Uri.parse('{{host}}/attendance/check-in'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${widget.token}',
          'x-api-key': 'odoo' // Replace with your JWT token
        },
        body: jsonEncode(<String, dynamic>{
          'check_in': dateTime,
          'checkin_latitude': position.latitude.toString(),
          'checkin_longitude': position.longitude.toString(),
          'checkin_address': address,
          'checkin_location':
              'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isCheckedIn = true;
          checkInTime = dateTime;
        });
        print('Check-in successful');
      } else {
        print('Check-in failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Check-in request failed with error: $e');
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await _determinePosition();
      String address =
          await _getAddressFromLatLng(position.latitude, position.longitude);
      String dateTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final response = await http.post(
        Uri.parse('{{host}}/attendance/check-out'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${widget.token}',
          'x-api-key': 'odoo' // Replace with your JWT token
        },
        body: jsonEncode(<String, dynamic>{
          'check_out': dateTime,
          'checkout_latitude': position.latitude.toString(),
          'checkout_longitude': position.longitude.toString(),
          'checkout_address': address,
          'checkout_location':
              'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
        }),
      );

      setState(() {
        _isLoading = false;
        _isCheckedIn = false;
        checkOutTime = dateTime;
        // Calculate worked hours here if needed
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Check-out successful');
      } else {
        print('Check-out failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Check-out request failed with error: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    Placemark place = placemarks[0];
    return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
                context); // This will take the user to the previous screen
          },
        ),
        title: Text('Attendance'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text("Mitchel Admin"),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 50), // Menambah jarak dari atas layar
                Card(
                  color: Colors.white, // Ubah warna kartu menjadi putih
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage(
                                  'assets/foto.jpg'), // Ganti dengan URL gambar avatar yang sesuai
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow('Name:', employeeName),
                        _buildInfoRow('Check-In:', checkInTime),
                        _buildInfoRow('Check-Out:', checkOutTime),
                        _buildInfoRow('Worked Hours:', workedHours),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                _isLoading
                    ? CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _isCheckedIn ? null : _checkIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isCheckedIn ? Colors.grey : Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                            ),
                            child: Text(
                              'Check-In',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isCheckedIn ? _checkOut : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isCheckedIn ? Colors.red : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                            ),
                            child: Text(
                              'Check-Out',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
