import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimeOffScreen(),
    );
  }
}

class TimeOffScreen extends StatefulWidget {
  @override
  _TimeOffScreenState createState() => _TimeOffScreenState();
}

class _TimeOffScreenState extends State<TimeOffScreen> {
  TextEditingController _dateFromController = TextEditingController();
  TextEditingController _dateToController = TextEditingController();
  TextEditingController _durationController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  int? _selectedTimeOffType;
  List<Map<String, dynamic>> _timeOffTypes = [];
  String? _attachedFileName;
  bool _isHalfDay = false;
  bool _isCustomHours = false;
  double? _hoursFrom;
  double? _hoursTo;

  @override
  void initState() {
    super.initState();
    _fetchTimeOffTypes();
  }

  Future<void> _fetchTimeOffTypes() async {
    try {
      final response = await http.get(
          Uri.parse('https://b095-103-3-220-146.ngrok-free.app/hr-leave-type'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _timeOffTypes = data.map((item) {
            return {
              'id': item['id'],
              'name': item['name'],
            };
          }).toList();
        });
      } else {
        print(
            'Failed to load time off types. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while fetching time off types: $e');
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];

        // If "Custom Hours" is selected, sync "Date To" with "Date From"
        if (_isCustomHours && controller == _dateFromController) {
          _dateToController.text = controller.text;
        }

        _calculateDuration();
      });
    }
  }

  // void _calculateDuration() {
  //   if (_isCustomHours) {
  //     if (_hoursFrom != null && _hoursTo != null) {
  //       // Calculate the duration based on the selected hours
  //       double duration = _hoursTo! - _hoursFrom!;

  //       if (duration > 0) {
  //         setState(() {
  //           _durationController.text = '${duration.toStringAsFixed(1)} hours';
  //         });
  //       } else {
  //         setState(() {
  //           _durationController.text = '0 hours';
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         _durationController.text = '0 hours';
  //       });
  //     }
  //   } else if (_dateFromController.text.isNotEmpty &&
  //       _dateToController.text.isNotEmpty) {
  //     DateTime fromDate = DateTime.parse(_dateFromController.text);
  //     DateTime toDate = DateTime.parse(_dateToController.text);
  //     int duration = toDate.difference(fromDate).inDays + 1;

  //     setState(() {
  //       if (duration >= 0) {
  //         if (_selectedTimeOffType != 1 && _selectedTimeOffType != 2) {
  //           if (_isHalfDay) {
  //             _durationController.text = '${duration * 4} hours';
  //           } else {
  //             _durationController.text = '${duration * 8} hours';
  //           }
  //         } else {
  //           _durationController.text = '$duration days';
  //         }
  //       } else {
  //         _durationController.text = '0 days';
  //       }
  //     });
  //   } else {
  //     setState(() {
  //       _durationController.text = '0 days';
  //     });
  //   }
  // }

  // Future<void> _pickFile() async {
  //   try {
  //     FilePickerResult? result = await FilePicker.platform.pickFiles();

  //     if (result != null) {
  //       setState(() {
  //         _attachedFileName = result.files.single.name;
  //       });
  //     } else {
  //       print('File picking was canceled.');
  //     }
  //   } catch (e) {
  //     print('Error occurred while picking a file: $e');
  //   }
  // }

  // Future<void> _submitForm() async {
  //   final selectedTypeId = _selectedTimeOffType;
  //   final dateFrom = _dateFromController.text;
  //   final dateTo = _dateToController.text;
  //   final durationText =
  //       _durationController.text.split(' ')[0]; // Extract only the numeric part
  //   final duration =
  //       double.tryParse(durationText) ?? 0; // Parse the numeric part
  //   String durationDisplay;

  //   if (selectedTypeId != 1 && selectedTypeId != 2) {
  //     durationDisplay = '$duration hours';
  //   } else {
  //     durationDisplay = '$duration days';
  //   }

  //   final description = _descriptionController.text;
  //   final attachedFile = _attachedFileName;
  //   final half_day = _isHalfDay;
  //   final custom_hours = _isCustomHours;

  //   print('Submitting the following data:');
  //   print('Time Off Type ID: $selectedTypeId');
  //   print('Date From: $dateFrom');
  //   print('Date To: $dateTo');
  //   print('Duration Display: $durationDisplay');
  //   print('Description: $description');
  //   print('Attached File: $attachedFile');
  //   print('Half day: $half_day');
  //   print('Custom hours: $custom_hours');
  //   print('Duration: $duration');

  //   final Map<String, dynamic> formData = {
  //     'holiday_status_id': selectedTypeId,
  //     'private_name': description,
  //     'request_date_from': dateFrom,
  //     'request_date_to': dateTo,
  //     'date_from': dateFrom,
  //     'date_to': dateTo,
  //     'number_of_days':
  //         duration, // This can be hours or days based on selection
  //     'duration_display': durationDisplay,
  //     'request_unit_half': half_day,
  //     'request_unit_hours': custom_hours,
  //     'requst_hours_from': _hoursFrom,
  //     'request_hours_to': _hoursTo,
  //   };

  //   final String token = ''; // Add your token here

  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://b095-103-3-220-146.ngrok-free.app/hr-leave'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: json.encode(formData),
  //     );

  //     if (response.statusCode == 200) {
  //       print('Form submitted successfully');
  //     } else {
  //       print('Failed to submit form. Status code: ${response.statusCode}');
  //       print('Response body: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error submitting form: $e');
  //   }
  // }
  void _calculateDuration() {
    if (_isCustomHours) {
      if (_hoursFrom != null && _hoursTo != null) {
        // Calculate the duration based on the selected hours
        double duration = _hoursTo! - _hoursFrom!;

        if (duration > 0) {
          setState(() {
            _durationController.text = '${duration.toStringAsFixed(1)} hours';
          });
        } else {
          setState(() {
            _durationController.text = '0 hours';
          });
        }
      } else {
        setState(() {
          _durationController.text = '0 hours';
        });
      }
    } else if (_dateFromController.text.isNotEmpty &&
        _dateToController.text.isNotEmpty) {
      DateTime fromDate = DateTime.parse(_dateFromController.text);
      DateTime toDate = DateTime.parse(_dateToController.text);
      int duration = toDate.difference(fromDate).inDays + 1; // Tambahkan 1 hari

      setState(() {
        if (duration >= 0) {
          if (_selectedTimeOffType != 1 && _selectedTimeOffType != 2) {
            if (_isHalfDay) {
              _durationController.text = '${duration * 4} hours';
            } else {
              _durationController.text = '${duration * 8} hours';
            }
          } else {
            _durationController.text = '$duration days';
          }
        } else {
          _durationController.text = '0 days';
        }
      });
    } else {
      setState(() {
        _durationController.text = '0 days';
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _attachedFileName = result.files.single.name;
        });
      } else {
        print('File picking was canceled.');
      }
    } catch (e) {
      print('Error occurred while picking a file: $e');
    }
  }

  Future<void> _submitForm() async {
    final selectedTypeId = _selectedTimeOffType;
    final dateFrom = _dateFromController.text;
    final dateTo = _dateToController.text;
    final durationText =
        _durationController.text.split(' ')[0]; // Extract only the numeric part
    final duration =
        double.tryParse(durationText) ?? 0; // Parse the numeric part
    String durationDisplay;

    if (selectedTypeId != 1 && selectedTypeId != 2) {
      durationDisplay = '$duration hours';
    } else {
      durationDisplay = '$duration days';
    }

    // Calculate number of days for custom hours
    double numberOfDays;
    if (_isCustomHours) {
      numberOfDays = duration / 8.0; // Assuming 8 hours per workday
    } else {
      numberOfDays = duration; // Use the duration directly for days
    }

    final description = _descriptionController.text;
    final attachedFile = _attachedFileName;
    final half_day = _isHalfDay;
    final custom_hours = _isCustomHours;

    print('Submitting the following data:');
    print('Time Off Type ID: $selectedTypeId');
    print('Date From: $dateFrom');
    print('Date To: $dateTo');
    print('Duration: $durationDisplay');
    print('Description: $description');
    print('Attached File: $attachedFile');
    print('Half day: $half_day');
    print('Custom hours: $custom_hours');
    print('Number of days: $numberOfDays');

    final Map<String, dynamic> formData = {
      'holiday_status_id': selectedTypeId,
      'private_name': description,
      'request_date_from': dateFrom,
      'request_date_to': dateTo,
      'date_from': dateFrom,
      'date_to': dateTo,
      'number_of_days': numberOfDays, // Use the calculated number of days
      'duration_display': durationDisplay,
      'request_unit_half': half_day,
      'request_unit_hours': custom_hours,
      'requst_hours_from': _hoursFrom,
      'request_hours_to': _hoursTo,
    };

    final String token = ''; // Add your token here

    try {
      final response = await http.post(
        Uri.parse('https://b095-103-3-220-146.ngrok-free.app/hr-leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(formData),
      );

      if (response.statusCode == 200) {
        print('Form submitted successfully');
      } else {
        print('Failed to submit form. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error submitting form: $e');
    }
  }

  List<DropdownMenuItem<double>> _generateHourOptions() {
    List<DropdownMenuItem<double>> hourOptions = [];
    for (double i = 1.0; i <= 24.0; i += 0.5) {
      hourOptions.add(
        DropdownMenuItem<double>(
          value: i,
          child: Text(i.toString()),
        ),
      );
    }
    return hourOptions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: const Text('Time Off'),
        actions: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('Mitchel Admin')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Card(
                color: Colors.white,
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedTimeOffType,
                        decoration: InputDecoration(
                          labelText: 'Time Off Type',
                          hintText: 'Select time off type',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 251, 251, 251),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _timeOffTypes.map((type) {
                          return DropdownMenuItem<int>(
                            value: type['id'],
                            child: Text(type['name']['en_US'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedTimeOffType = newValue;
                            print(
                                'Selected Time Off Type ID: $_selectedTimeOffType');
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedTimeOffType != 1 &&
                          _selectedTimeOffType != 2)
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Half Day'),
                                value: _isHalfDay,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _isHalfDay = newValue ?? false;
                                    if (_isHalfDay) {
                                      _isCustomHours = false;
                                      _calculateDuration(); // Recalculate duration
                                    }
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Custom Hours'),
                                value: _isCustomHours,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _isCustomHours = newValue ?? false;
                                    if (_isCustomHours) {
                                      _isHalfDay = false;
                                      _calculateDuration(); // Recalculate duration
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateFromController,
                        decoration: InputDecoration(
                          labelText: 'Date From',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 251, 251, 251),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () {
                              _selectDate(context, _dateFromController);
                            },
                          ),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateToController,
                        decoration: InputDecoration(
                          labelText: 'Date To',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 251, 251, 251),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () {
                              _selectDate(context, _dateToController);
                            },
                          ),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      if (_isCustomHours)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                value: _hoursFrom,
                                decoration: InputDecoration(
                                  labelText: 'Hours From',
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 251, 251, 251),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _generateHourOptions(),
                                onChanged: (double? newValue) {
                                  setState(() {
                                    _hoursFrom = newValue;
                                    _calculateDuration(); // Recalculate duration when hours change
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                value: _hoursTo,
                                decoration: InputDecoration(
                                  labelText: 'Hours To',
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 251, 251, 251),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _generateHourOptions(),
                                onChanged: (double? newValue) {
                                  setState(() {
                                    _hoursTo = newValue;
                                    _calculateDuration(); // Recalculate duration when hours change
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 251, 251, 251),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 251, 251, 251),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Attach File'),
                          ),
                          if (_attachedFileName != null)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  _attachedFileName!,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
