import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'Log.dart';
import 'package:flutter/cupertino.dart';

String Username = "";
List<String> patientNames = [];
String SelectedPatient = "";
String PatientFile = '';
String SelectedWeekPlan = "";
var weekplan = [];

String removeControlCharacters() {
  RegExp controlCharactersRegex = RegExp(r'[\x00-\x1F\x7F]');
  return PatientFile.replaceAll(controlCharactersRegex, '');
}

List<String> extractPatientNames(String response) {
  final RegExp pattern = RegExp(r'(\w+)%25\.\.%25');

  List<String> patientNames = [];

  Iterable<Match> matches = pattern.allMatches(response);

  for (var match in matches) {
    String patientName = match.group(1) ?? '';
    if (patientName.startsWith('25')) {
      patientName = patientName.substring(2);
    }
    if (patientName.isNotEmpty) {
      patientNames.add(patientName);
    }
  }

  print(patientNames);
  return patientNames;
}

getPatientFile() async {
  String patientIDWithSpecialChars = await getPatientID();
  String pID = patientIDWithSpecialChars.split('%')[0];
  String url =
      'https://server---app-d244e2f2d7c9.herokuapp.com/getPatientFile/';

  try {
    http.Response response = await http.get(Uri.parse('$url?pID=$pID'));

    if (response.statusCode == 200) {
      PatientFile = response.body;
    } else if (response.statusCode == 404) {
      print('No user or file found.');
    } else {
      print('Error: ${response.statusCode}');
    }
  } catch (error) {
    print('Error: $error');
  }
}

Future<String> getPatientID() async {
  String url = 'https://server---app-d244e2f2d7c9.herokuapp.com/getPatientID/';

  try {
    http.Response response =
        await http.get(Uri.parse('$url?userName=$SelectedPatient'));

    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 404) {
      print('No user or file found.');
      return '';
    } else {
      print('Error: ${response.statusCode}');
      return '';
    }
  } catch (error) {
    print('Error: $error');
    return '';
  }
}

class MainPage extends StatefulWidget {
  final String username;
  final String responseBody;

  const MainPage({Key? key, required this.username, required this.responseBody})
      : super(key: key);

  @override
  _MainPageState createState() =>
      _MainPageState(username: username, responseBody: responseBody);
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages = [];

  final String username;
  final String responseBody;

  _MainPageState({required this.username, required this.responseBody}) {
    Username = username;
    patientNames = extractPatientNames(responseBody);

    _pages = [
      WelcomePage(),
      Patients(responseBody: responseBody),
      WeekPlan(),
    ];
    _selectedIndex = 0;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Monitor',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          leading: null,
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            'Monitor',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(CupertinoIcons.house_fill),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 24, 81, 128),
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              buildListTile('Welcome', 0),
              buildListTile('Patients', 1),
              buildListTile('WeekPlan', 2),
              buildListTile('LogOut', 3),
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          child: _pages[_selectedIndex],
        ),
      );
    }
  }

  Widget buildListTile(String title, int index) {
    return InkWell(
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
      splashColor: Color.fromARGB(255, 24, 81, 128).withOpacity(0.5),
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        title: Text(title),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Welcome'),
    );
  }
}

class WeekPlan extends StatefulWidget {
  WeekPlan();

  @override
  _WeekPlanState createState() => _WeekPlanState();
}

class _WeekPlanState extends State<WeekPlan> {
  final TextEditingController _weekPlanNameController = TextEditingController();
  DateTime? _selectedDate;

  List<String> GetWeekPlans() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());

      if (response.containsKey('plans') &&
          response['plans'] != null &&
          response['plans'].isNotEmpty) {
        List<String> weekPlans = [];

        for (var plan in response['plans']) {
          String name = plan['weekPlanName'];
          weekPlans.add(name);
        }

        return weekPlans;
      } else {
        return [];
      }
    } catch (e) {
      print('Error parsing JSON: $e');
      return ['Error'];
    }
  }

  void addWeekPlan(String weekPlanName, DateTime selectedDate) async {
    String patientFileString = await removeControlCharacters();
    Map<String, dynamic> patientFileMap = jsonDecode(patientFileString) ?? {};

    if (!patientFileMap.containsKey('coachName') ||
        patientFileMap['coachName'] == null) {
      patientFileMap['coachName'] = Username;
    }

    if (!patientFileMap.containsKey('patientName') ||
        patientFileMap['patientName'] == null) {
      patientFileMap['patientName'] = SelectedPatient;
    }

    String patientID = await getPatientID();
    if (!patientFileMap.containsKey('patientID') ||
        patientFileMap['patientID'] == null) {
      patientFileMap['patientID'] = patientID;
    }

    if (!patientFileMap.containsKey('plans') ||
        patientFileMap['plans'] == null) {
      patientFileMap['plans'] = [];
    }

    String startDate =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    DateTime endDate = selectedDate.add(Duration(days: 6));
    String endDateString = '${endDate.day}/${endDate.month}/${endDate.year}';

    int weekPlanID = patientFileMap['plans'].length + 1;

    patientFileMap['plans'].add({
      'weekPlanID': weekPlanID.toString(),
      'weekPlanName': weekPlanName,
      'weekPlanSDate': startDate,
      'weekPlanEDate': endDateString,
      'weekPlan': _initializeWeekPlan()
    });

    setState(() {
      String updatedPatientFile = jsonEncode(patientFileMap);
      PatientFile = updatedPatientFile;
    });

    await postUpdatedPatientFile(patientFileMap);
  }

  List<Map<String, dynamic>> _initializeWeekPlan() {
    List<Map<String, dynamic>> weekPlan = [];

    for (int i = 0; i < 7; i++) {
      weekPlan.add({
        'dayName': _getDayName(i),
        'dayID': (i + 1).toString(),
        'dayProgress': '0.0',
        'totalTasksDration': '0',
        'numberOfTasks': '0',
        'timeSlots': List.filled(144, 0).join(','),
        'tasks': []
      });
    }

    return weekPlan;
  }

  String _getDayName(int index) {
    const dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return dayNames[index % 7];
  }

  Future<void> postUpdatedPatientFile(
      Map<String, dynamic> patientFileMap) async {
    String url =
        'https://server---app-d244e2f2d7c9.herokuapp.com/setPatientFile';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file': patientFileMap,
          'patientName': patientFileMap['patientName'],
        }),
      );

      if (response.statusCode == 200) {
        print('Patient file updated successfully');
      } else {
        print('Failed to update patient file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting patient file: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime initialDate = currentDate;
    while (initialDate.weekday != DateTime.monday) {
      initialDate = initialDate.add(Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        return date.weekday == DateTime.monday;
      },
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddWeekPlanDialog() {
    _weekPlanNameController.clear();
    setState(() {
      _selectedDate = null;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                "New WeekPlan",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _weekPlanNameController,
                      decoration: InputDecoration(
                        labelText: "WeekPlan Name",
                        labelStyle:
                            TextStyle(color: Theme.of(context).primaryColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      cursorColor: Theme.of(context).primaryColor,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectDate(context).then((_) {
                        setState(() {});
                      }),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: Colors.grey)),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? "No date selected"
                              : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text("Close",
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: Text("Add",
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        addWeekPlan(
                          _weekPlanNameController.text,
                          _selectedDate!,
                        );
                        print(
                            "Week plan added: ${_weekPlanNameController.text} on ${_selectedDate.toString()}");
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> weekPlans = GetWeekPlans();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          SelectedPatient.isEmpty
              ? 'No patient selected'
              : 'Week Plans for ${SelectedPatient}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            if (SelectedPatient.isEmpty) Text("No patient selected."),
            if (SelectedPatient.isNotEmpty)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: Colors.blue, size: 40),
                  onPressed: _showAddWeekPlanDialog,
                ),
              ),
            SizedBox(
              height: 10,
            ),
            if (weekPlans.isNotEmpty && SelectedPatient.isNotEmpty)
              Wrap(
                direction: Axis.vertical,
                spacing: 10.0,
                children: [
                  for (var plan in weekPlans)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            SelectedWeekPlan = plan;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientTasks(),
                              ),
                            );
                          },
                          child: Text(
                            plan,
                            style: TextStyle(color: Colors.blue, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class PatientTasks extends StatefulWidget {
  @override
  _PatientTasksState createState() => _PatientTasksState();
}

class _PatientTasksState extends State<PatientTasks> {
  int _selectedIndex = 0;

  List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  String removeControlCharacters() {
    RegExp controlCharactersRegex = RegExp(r'[\x00-\x1F\x7F]');
    return PatientFile.replaceAll(controlCharactersRegex, '');
  }

  void showProgressChartDialog(BuildContext context) {
    List<FlSpot> seriesList = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), 0),
    );
    try {
      for (int i = 0; i < weekplan.length; i++) {
        double dayProgress = double.tryParse(weekplan[i][1].toString()) ?? 0.0;
        if (dayProgress < 0.99) {
          dayProgress *= 100;
        }
        seriesList[i] = FlSpot(i.toDouble(), dayProgress);
      }
    } catch (e) {
      print('Error: $e');
    }

    List<String> dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Total Week Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 24, 81, 128),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: seriesList,
                          isCurved: true,
                          colors: [Color.fromARGB(255, 24, 81, 128)],
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          margin: 20,
                          rotateAngle: 45,
                          getTitles: (value) {
                            if (value % 1 == 0) {
                              return dayNames[value.toInt()];
                            }
                            return '';
                          },
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) => const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          margin: 8,
                          reservedSize: 30,
                          interval: 10,
                          getTitles: (value) {
                            return value.toInt().toString();
                          },
                        ),
                        rightTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 24, 81, 128),
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String getName() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['patientName'];
    } catch (e) {
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  void _addTaskToWeekPlan(
      BuildContext context,
      String taskTitle,
      String description,
      TimeOfDay? startTime,
      TimeOfDay? endTime,
      String day,
      String program) {
    Map<String, dynamic> patientFileMap = jsonDecode(removeControlCharacters());
    List<dynamic> plans = patientFileMap['plans'] ?? [];
    List<dynamic> programs = [];
    programs.add({'baseName': program});

    for (var plan in plans) {
      if (plan['weekPlanName'] == SelectedWeekPlan) {
        weekplan = plan['weekPlan'] ?? [];

        for (var dayPlanData in weekplan) {
          if (dayPlanData['dayName'] == day) {
            List<dynamic> tasks = dayPlanData['tasks'] ?? [];

            int taskDuration = 0;
            if (startTime != null && endTime != null) {
              int startMinutes = startTime.hour * 60 + startTime.minute;
              int endMinutes = endTime.hour * 60 + endTime.minute;
              taskDuration = endMinutes - startMinutes;
            }

            int taskIndex =
                tasks.indexWhere((task) => task['taskName'] == taskTitle);
            if (taskIndex != -1) {
              tasks.removeAt(taskIndex);
            }

            tasks.add({
              'taskID': (tasks.length + 1).toString(),
              'taskName': taskTitle,
              'description': description,
              'startTime': startTime != null
                  ? "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}"
                  : "",
              'endTime': endTime != null
                  ? "${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}"
                  : "",
              'taskDuration': taskDuration.toString(),
              'taskProgress': '0',
              'taskReview': '',
              'startTimeH': startTime != null ? startTime.hour.toString() : '0',
              'startTimeM':
                  startTime != null ? startTime.minute.toString() : '0',
              'endTimeH': endTime != null ? endTime.hour.toString() : '0',
              'endTimeM': endTime != null ? endTime.minute.toString() : '0',
              'submitted': 'false',
              'percentageOfDay': '0.0',
              'status': 'Not started',
              'submittedPercentage': '0.0',
              'programs': programs,
            });

            dayPlanData['tasks'] = tasks;
            dayPlanData['numberOfTasks'] = ((int.tryParse(
                            dayPlanData['numberOfTasks']?.toString() ?? '0') ??
                        0) +
                    1)
                .toString();
            dayPlanData['totalTasksDration'] = ((int.tryParse(
                            dayPlanData['totalTasksDration']?.toString() ??
                                '0') ??
                        0) +
                    taskDuration)
                .toString();
            break;
          }
        }
        break;
      }
    }

    patientFileMap['plans'] = plans;
    PatientFile = jsonEncode(patientFileMap);
    setState(() {});
    postUpdatedPatientFile();
  }

  void _showAddTaskDialog(BuildContext context, String day,
      [String? taskName]) {
    TextEditingController _taskTitleController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();
    TextEditingController _programsController = TextEditingController();

    TimeOfDay? _startTime;
    TimeOfDay? _endTime;

    if (taskName != null) {
      Map<String, dynamic> patientFileMap =
          jsonDecode(removeControlCharacters());
      List<dynamic> plans = patientFileMap['plans'] ?? [];
      for (var plan in plans) {
        if (plan['weekPlanName'] == SelectedWeekPlan) {
          weekplan = plan['weekPlan'] ?? [];
          for (var dayPlanData in weekplan) {
            if (dayPlanData['dayName'] == day) {
              List<dynamic> tasks = dayPlanData['tasks'] ?? [];
              for (var task in tasks) {
                if (task['taskName'] == taskName) {
                  _taskTitleController.text = task['taskName'] ?? '';
                  _descriptionController.text = task['description'] ?? '';
                  _startTime = TimeOfDay(
                      hour: int.parse(task['startTimeH'] ?? '0'),
                      minute: int.parse(task['startTimeM'] ?? '0'));
                  _endTime = TimeOfDay(
                      hour: int.parse(task['endTimeH'] ?? '0'),
                      minute: int.parse(task['endTimeM'] ?? '0'));
                  break;
                }
              }
              break;
            }
          }
          break;
        }
      }
    }

    Future<void> _selectTime(
        BuildContext context, bool isStartTime, Function setState) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: isStartTime
            ? _startTime ?? TimeOfDay.now()
            : _endTime ?? TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Color.fromARGB(255, 16, 63, 102),
                onPrimary: Colors.white,
                onSurface: Colors.blue,
              ),
              buttonTheme: ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          if (isStartTime) {
            _startTime = picked;
          } else {
            _endTime = picked;
          }
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Center(
                child: Text(
                  taskName == null ? 'Add Task for $day' : 'Edit Task for $day',
                  style: TextStyle(
                    color: Color.fromARGB(255, 16, 63, 102),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _taskTitleController,
                      decoration: InputDecoration(
                        labelText: "Task Title*",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectTime(context, true, setState),
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: _startTime == null
                                ? "Start Time*"
                                : "Start Time: ${_startTime!.format(context)}",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectTime(context, false, setState),
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: _endTime == null
                                ? "End Time*"
                                : "End Time: ${_endTime!.format(context)}",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _programsController,
                      decoration: InputDecoration(
                        labelText: "Programs Needed",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 16, 63, 102),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    taskName == null ? "Add" : "Update",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 16, 63, 102),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addTaskToWeekPlan(
                      context,
                      _taskTitleController.text,
                      _descriptionController.text,
                      _startTime,
                      _endTime,
                      day,
                      _programsController.text,
                    );
                    PatientFile = getPatientFile();
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> postUpdatedPatientFile() async {
    String url =
        'https://server---app-d244e2f2d7c9.herokuapp.com/setPatientFile';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file': PatientFile,
          'patientName': SelectedPatient,
        }),
      );

      if (response.statusCode == 200) {
        print('Patient file updated successfully');
      } else {
        print('Failed to update patient file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting patient file: $e');
    }
  }

  List<String> getRange() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());

      if (response.containsKey('plans') &&
          response['plans'] != null &&
          response['plans'].isNotEmpty) {
        DateTime currentDate = DateTime.now();

        for (var plan in response['plans']) {
          String startDateString = plan['weekPlanSDate'];
          String endDateString = plan['weekPlanEDate'];

          List<String> startDateParts =
              (plan['weekPlanSDate'] as String).split('/');
          DateTime planStartDate = DateTime(
            int.parse(startDateParts[2]),
            int.parse(startDateParts[1]),
            int.parse(startDateParts[0]),
          );
          List<String> endDateParts =
              (plan['weekPlanEDate'] as String).split('/');
          DateTime planEndDate = DateTime(
            int.parse(endDateParts[2]),
            int.parse(endDateParts[1]),
            int.parse(endDateParts[0]),
          );

          if (currentDate.year == planStartDate.year &&
                  currentDate.month == planStartDate.month &&
                  currentDate.day == planStartDate.day ||
              currentDate.year == planEndDate.year &&
                  currentDate.month == planEndDate.month &&
                  currentDate.day == planEndDate.day ||
              (currentDate.isAfter(planStartDate) &&
                  currentDate.isBefore(planEndDate))) {
            return [startDateString, endDateString];
          }
        }

        return ['', ''];
      } else {
        return ['', ''];
      }
    } catch (e) {
      print('Error parsing JSON: $e');
      return ['Error', 'Error'];
    }
  }

  @override
  Widget build(BuildContext context) {
    String patientName = getName();
    List<String> date = getRange();
    String start = date[0];
    String end = date[1];

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 35),
          child: Text(
            'Patient : $patientName',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: DefaultTabController(
        length: 7,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10),
            ),
            TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              tabs: [
                Tab(text: 'Monday'),
                Tab(text: 'Tuesday'),
                Tab(text: 'Wednesday'),
                Tab(text: 'Thursday'),
                Tab(text: 'Friday'),
                Tab(text: 'Saturday'),
                Tab(text: 'Sunday'),
              ],
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            Expanded(
              child: TabBarView(
                children: _days.map((day) => _buildDayBlock(day)).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _showAddTaskDialog(context, _days[_selectedIndex]);
            },
            backgroundColor: Color.fromARGB(255, 16, 63, 102),
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              showProgressChartDialog(context);
            },
            backgroundColor: Color.fromARGB(255, 16, 63, 102),
            child: Icon(
              Icons.assessment,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    final ScrollController _scrollController = ScrollController();

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color.fromARGB(255, 24, 81, 128),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  width: 200,
                  child: Text(
                    'No Plans yet for This Patient',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 16, 63, 102),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBlock(String day) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(removeControlCharacters());
      List<dynamic> plans = jsonData['plans'];
      Map<String, dynamic> dayPlan = {};

      if (plans == null || plans.isEmpty) {
        return _buildNoDataWidget();
      }
      for (var plan in plans) {
        List<String> startDateParts =
            (plan['weekPlanSDate'] as String).split('/');
        DateTime planStartDate = DateTime(
          int.parse(startDateParts[2]),
          int.parse(startDateParts[1]),
          int.parse(startDateParts[0]),
        );
        List<String> endDateParts =
            (plan['weekPlanEDate'] as String).split('/');
        DateTime planEndDate = DateTime(
          int.parse(endDateParts[2]),
          int.parse(endDateParts[1]),
          int.parse(endDateParts[0]),
        );
        String WeekName = plan['weekPlanName'];
        if (WeekName == SelectedWeekPlan) {
          weekplan = plan['weekPlan'];

          for (var dayPlanData in weekplan) {
            if (dayPlanData['dayName'] == day) {
              dayPlan = dayPlanData;
              break;
            }
          }
          if (dayPlan.isNotEmpty) {
            break;
          }
        }
        if (dayPlan.isEmpty) {
          continue;
        } else {
          continue;
        }
      }

      List<dynamic> tasks = dayPlan['tasks'];

      return Expanded(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Color.fromARGB(255, 24, 81, 128),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color.fromARGB(255, 24, 81, 128),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 16, 63, 102),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 100,
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Column(
                    children: tasks.map<Widget>((task) {
                      bool isDone = task['submitted'] == 'true';
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color.fromARGB(255, 16, 63, 102)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TaskItem(
                                task: task['taskName'],
                                isDone: isDone,
                                day: day,
                                showAddTaskDialog: _showAddTaskDialog,
                                taskData: task),
                          ),
                          SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error parsing JSON: $e');
      return SizedBox.shrink();
    }
  }
}

class TaskItem extends StatefulWidget {
  final String task;
  final bool isDone;
  final String day;
  final Map<String, dynamic> taskData;
  final Function(BuildContext context, String day, [String? taskName])
      showAddTaskDialog;

  const TaskItem({
    Key? key,
    required this.task,
    this.isDone = false,
    required this.day,
    required this.taskData,
    required this.showAddTaskDialog,
  }) : super(key: key);

  @override
  _TaskItemState createState() =>
      _TaskItemState(taskName: task, day: day, taskData: taskData);
}

class _TaskItemState extends State<TaskItem> {
  bool _isHovered = false;
  final String taskName;
  final Map<String, dynamic> taskData;
  final String day;
  _TaskItemState(
      {required this.taskName, required this.day, required this.taskData});
  String getname() {
    return taskData['taskName'] ?? 'Unnamed Task';
  }

  Map<String, dynamic> getTaskData() {
    return taskData;
  }

  String getST() {
    return taskData['startTime'] ?? 'No start time';
  }

  String getET() {
    return taskData['endTime'] ?? 'No end time';
  }

  String getDesc() {
    return taskData['description'] ?? 'No description';
  }

  String duration() {
    return taskData['taskDuration'] ?? 'No duration';
  }

  String taskReview() {
    return taskData['Review'] ?? 'No review';
  }

  String Prog() {
    return taskData['taskProgress'] ?? 'No progress';
  }

  String SubPer() {
    return taskData['submittedPercentage'] ?? '0';
  }

  String PercOfD() {
    return taskData['percentageOfDay'] ?? '0';
  }

  List<dynamic> Programs() {
    return taskData['programs'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    String taskName = getname();
    String startTime = getST();
    String endTime = getET();
    String description = getDesc();
    String submittedPercentage = SubPer();
    List<dynamic> programs = Programs();
    String programNames = '';
    String taskreview = taskReview();
    for (var program in programs) {
      String baseName = program['baseName'] ?? 'Unnamed Program';
      programNames += '$baseName, ';
    }
    programNames = programNames.isNotEmpty
        ? programNames.substring(0, programNames.length - 2)
        : '';
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isDone
                    ? CupertinoIcons.check_mark
                    : CupertinoIcons.xmark,
                color: widget.isDone
                    ? Color.fromARGB(255, 24, 81, 128)
                    : Color.fromARGB(255, 24, 81, 128),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: AlertDialog(
                          title: Center(
                            child: Text(
                              'Task Details',
                              style: TextStyle(
                                color: Color.fromARGB(255, 16, 63, 102),
                              ),
                            ),
                          ),
                          content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Task Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $taskName',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Start Time',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $startTime',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'End Time',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $endTime',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Description',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $description',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Submitted Percentage',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $submittedPercentage',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Programs',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $programNames',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Task Review',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 16, 63, 102)),
                                      ),
                                      TextSpan(
                                        text: ': $taskreview',
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                          actions: [
                            if (!widget.isDone)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.showAddTaskDialog(
                                      context, day, taskName);
                                },
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 24, 81, 128),
                                  ),
                                ),
                              ),
                            if (!widget.isDone)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Close',
                                    style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  widget.task,
                  style: TextStyle(
                    fontSize: 20,
                    color: _isHovered
                        ? Colors.green
                        : Color.fromARGB(255, 24, 81, 128),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Patients extends StatefulWidget {
  final String responseBody;
  const Patients({Key? key, required this.responseBody}) : super(key: key);
  @override
  _PatientsState createState() => _PatientsState(responseBody: responseBody);
}

class _PatientsState extends State<Patients> {
  String _selectedPatient = '';
  Offset _position = Offset(0, 0);
  final String responseBody;
  List<String> patientNames = [];

  _PatientsState({required this.responseBody});

  @override
  void initState() {
    super.initState();
    patientNames = extractPatientNames(responseBody);
  }

  void _showOptions(BuildContext context, String patientName, Offset position) {
    setState(() {
      _selectedPatient = patientName;
      _position = position;
    });
  }

  Future<List<String>> fetchAvailablePatients() async {
    String url =
        "https://server---app-d244e2f2d7c9.herokuapp.com/getAvailablePatients/";

    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        String responseBody = response.body.trim();
        if (responseBody.isNotEmpty) {
          List<String> patients = responseBody.split(',');
          return patients;
        } else {
          print('Unexpected response format.');
          return [];
        }
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error: $error');
      return [];
    }
  }

  Future<void> addPatient(String patientName) async {
    String url = "https://server---app-d244e2f2d7c9.herokuapp.com/addPatient/";
    String queryString = "?coachName=$Username&patientName=$patientName";

    try {
      http.Response response = await http.get(Uri.parse(url + queryString));

      if (response.statusCode == 200) {
        print("Patient added successfully: $patientName");
        setState(() {
          patientNames.add(patientName);
        });
      } else {
        print('Error adding patient: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showAvailablePatientsDialog(BuildContext context) async {
    List<String> availablePatients = await fetchAvailablePatients();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Available Patients"),
          content: SingleChildScrollView(
            child: ListBody(
              children: availablePatients.map((patient) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(patient),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          print("added $patient");
                          addPatient(patient);
                        },
                        child: Text(
                          "Add",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                "Close",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void openChatWindow(String patientname) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Page1(patientname: patientname),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose patient',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.all(10.0),
        child: Stack(
          children: [
            Wrap(
              spacing: 20.0,
              runSpacing: 20.0,
              children: [
                GestureDetector(
                  onTap: () {
                    _showAvailablePatientsDialog(context);
                  },
                  child: Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.blue, size: 40),
                          SizedBox(height: 8),
                          Text(
                            "Add",
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                for (var patientName in patientNames)
                  GestureDetector(
                    onTapDown: (details) {
                      _showOptions(
                        context,
                        patientName,
                        details.globalPosition,
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: Colors.blue, size: 40),
                            SizedBox(height: 8),
                            Text(
                              patientName,
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_selectedPatient.isNotEmpty)
              Positioned(
                left: _position.dx - 100,
                top: _position.dy - 100,
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    width: 200,
                    height: 100,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Choose', style: TextStyle(fontSize: 14)),
                          onTap: () {
                            setState(() {
                              SelectedPatient = _selectedPatient;
                              _selectedPatient = '';
                              getPatientFile();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Patient $SelectedPatient is Picked'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.chat),
                          title: Text('Chat', style: TextStyle(fontSize: 14)),
                          onTap: () {
                            openChatWindow(_selectedPatient);
                            setState(() {
                              _selectedPatient = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Page1 extends StatefulWidget {
  final String patientname;

  const Page1({Key? key, required this.patientname}) : super(key: key);

  @override
  _Page1State createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  List<ChatMessage> messages = [];
  Timer? timer;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getChat();
    timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      getChat();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void getChat() async {
    String C = Username;
    String P = widget.patientname;
    String url = 'https://server---app-d244e2f2d7c9.herokuapp.com/getChat/';

    try {
      http.Response response =
          await http.get(Uri.parse('$url?patientName=$P&coachName=$C'));

      if (response.statusCode == 200) {
        String responseBody = response.body;
        if (responseBody.isNotEmpty) {
          List<dynamic> responseBodyChat = json.decode(responseBody);
          Map<String, dynamic> inboxData = responseBodyChat[0];
          List<dynamic> inbox = inboxData['inbox'];
          List<ChatMessage> fetchedMessages = [];

          for (var messageData in inbox) {
            String messageString = messageData;

            List<String> parts = messageString.split(':');

            String sender = parts[0].trim();
            String text = parts[1].trim();

            fetchedMessages.add(ChatMessage(sender: sender, text: text));
          }

          if (!mounted) return;
          setState(() {
            messages.clear();
            messages.addAll(fetchedMessages);
          });
        } else {
          setState(() {
            messages.clear();
          });
        }
      } else if (response.statusCode == 404) {
        print('No user or file found.');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void sendChat(String message) async {
    String C = Username;
    String P = widget.patientname;
    String url = 'https://server---app-d244e2f2d7c9.herokuapp.com/sendMassege/';
    try {
      http.Response response = await http.post(
        Uri.parse('$url?patientName=$P&coachName=$C&message=$message'),
      );

      if (response.statusCode == 200) {
        print('Success');
      } else if (response.statusCode == 404) {
        print('No user or file found.');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  String getName() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['patientName'];
    } catch (e) {
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  String getCname() {
    try {
      Map<String, dynamic> response = jsonDecode(removeControlCharacters());
      return response['coachName'];
    } catch (e) {
      print('Error parsing JSON: $e');
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Chat'),
        leading: null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                for (var message in messages)
                  ChatMessage(
                    sender: message.sender,
                    text: message.text,
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    String message = _messageController.text;
                    if (message.isNotEmpty) {
                      sendChat(message);
                      getChat();
                      _messageController.clear();
                      setState(() {});
                    } else {}
                  },
                  child: Text(
                    'Send',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String sender;
  final String text;

  const ChatMessage({Key? key, required this.sender, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 24, 81, 128),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                sender,
                style: TextStyle(
                  color: Color.fromARGB(255, 24, 81, 128),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
