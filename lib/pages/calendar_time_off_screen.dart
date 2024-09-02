import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'time_off_screen.dart';

class CalendarTimeOffScreen extends StatefulWidget {
  final String token;

  CalendarTimeOffScreen({required this.token});

  @override
  _CalendarTimeOffScreenState createState() => _CalendarTimeOffScreenState();
}

class _CalendarTimeOffScreenState extends State<CalendarTimeOffScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedHolidayStatusName;
  String? _selectedDescription;
  List<dynamic> _timeOffData = [];
  bool _isLoading = true;

  final Map<int, Color> _holidayStatusColors = {
    1: Colors.redAccent,
    2: Colors.blueAccent,
    3: Colors.greenAccent,
    4: Colors.yellowAccent,
  };

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final url = 'https://odoo-api-rust.vercel.app/hr-leave/by-employee';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'x-api-key': 'odoo',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _timeOffData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        logError('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      logError('Error fetching data: $e');
    }
  }

  void logError(String message) {
    print(message);
  }

  void _navigateToNextPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeOffScreen(token: widget.token),
      ),
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    DateTime startDate = DateTime(start.year, start.month, start.day);
    DateTime endDate = DateTime(end.year, end.month, end.day);
    DateTime checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(startDate.subtract(Duration(days: 1))) &&
        checkDate.isBefore(endDate.add(Duration(days: 1)));
  }

  Color? _getColorForDate(DateTime date) {
    for (var timeOff in _timeOffData) {
      String? requestDateFromStr = timeOff['request_date_from'];
      String? requestDateToStr = timeOff['request_date_to'];
      int? holidayStatusId = timeOff['holiday_status_id'];

      if (requestDateFromStr != null &&
          requestDateToStr != null &&
          holidayStatusId != null) {
        DateTime requestDateFrom = DateTime.parse(requestDateFromStr);
        DateTime requestDateTo = DateTime.parse(requestDateToStr);

        if (isDateInRange(date, requestDateFrom, requestDateTo)) {
          return _holidayStatusColors[holidayStatusId] ?? Colors.grey;
        }
      }
    }
    return null;
  }

  int? _getHolidayStatusIdForDate(DateTime date) {
    for (var timeOff in _timeOffData) {
      String? requestDateFromStr = timeOff['request_date_from'];
      String? requestDateToStr = timeOff['request_date_to'];
      int? holidayStatusId = timeOff['holiday_status_id'];

      if (requestDateFromStr != null &&
          requestDateToStr != null &&
          holidayStatusId != null) {
        DateTime requestDateFrom = DateTime.parse(requestDateFromStr);
        DateTime requestDateTo = DateTime.parse(requestDateToStr);

        if (isDateInRange(date, requestDateFrom, requestDateTo)) {
          return holidayStatusId;
        }
      }
    }
    return null;
  }

  String? _getHolidayStatusNameForDate(DateTime date) {
    for (var timeOff in _timeOffData) {
      String? requestDateFromStr = timeOff['request_date_from'];
      String? requestDateToStr = timeOff['request_date_to'];
      var holidayStatus = timeOff['holidayStatus'];

      if (requestDateFromStr != null &&
          requestDateToStr != null &&
          holidayStatus != null) {
        DateTime requestDateFrom = DateTime.parse(requestDateFromStr);
        DateTime requestDateTo = DateTime.parse(requestDateToStr);

        if (isDateInRange(date, requestDateFrom, requestDateTo)) {
          return holidayStatus['name']['en_US'];
        }
      }
    }
    return null;
  }

  String? _getDescriptionForDate(DateTime date) {
    for (var timeOff in _timeOffData) {
      String? requestDateFromStr = timeOff['request_date_from'];
      String? requestDateToStr = timeOff['request_date_to'];
      String? privateName = timeOff['private_name'];

      if (requestDateFromStr != null &&
          requestDateToStr != null &&
          privateName != null) {
        DateTime requestDateFrom = DateTime.parse(requestDateFromStr);
        DateTime requestDateTo = DateTime.parse(requestDateToStr);

        if (isDateInRange(date, requestDateFrom, requestDateTo)) {
          return privateName;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Off'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.white,
                        elevation: 8.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TableCalendar(
                                firstDay: DateTime.utc(2000, 1, 1),
                                lastDay: DateTime.utc(2100, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) {
                                  return isSameDate(_selectedDay, day);
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;

                                    _selectedHolidayStatusName =
                                        _getHolidayStatusNameForDate(
                                            selectedDay);
                                    _selectedDescription =
                                        _getDescriptionForDate(selectedDay);
                                  });
                                },
                                calendarFormat: _calendarFormat,
                                onFormatChanged: (format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                },
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder: (context, date, _) {
                                    final color = _getColorForDate(date);
                                    if (color != null) {
                                      return Container(
                                        margin: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${date.day}',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Divider(
                                thickness: 2.0,
                                color: Colors.black,
                              ),
                              const SizedBox(height: 16),
                              if (_selectedHolidayStatusName != null &&
                                  _selectedDescription != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Holiday Status: $_selectedHolidayStatusName',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Description: $_selectedDescription',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.blueGrey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              if (_timeOffData.isNotEmpty)
                                Column(
                                  children: _timeOffData.map((data) {
                                    return ListTile(
                                      title: Text(
                                          'Request Date From: ${data['request_date_from'] ?? 'N/A'}'),
                                      subtitle: Text(
                                          'Request Date To: ${data['request_date_to'] ?? 'N/A'}'),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _navigateToNextPage(context),
                child: const Text('Ajukan Cuti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
