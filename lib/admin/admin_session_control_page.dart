import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSessionControlPage extends StatefulWidget {
  final String? coachId;

  const AdminSessionControlPage({super.key, this.coachId});

  @override
  State<AdminSessionControlPage> createState() => _AdminSessionControlPageState();
}

class _AdminSessionControlPageState extends State<AdminSessionControlPage> {
  final List<String> days = ['Pzt', 'Sal', 'Çrş', 'Prş', 'Cum', 'Cts', 'Pzr'];
  final List<String> hours = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  Map<String, Map<String, List<Map<String, String>>>> schedule = {};
  List<String> coachBranches = [];
  String? selectedBranch;
  List<Map<String, dynamic>> sessionStudents = []; // Seansa kayıtlı öğrenciler

  @override
  void initState() {
    super.initState();

    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = [];
      }
    }
  }

  Stream<DocumentSnapshot> _getCoachScheduleStream() {
    if (widget.coachId != null) {
      return FirebaseFirestore.instance.collection('users').doc(widget.coachId).snapshots();
    } else {
      return const Stream.empty();
    }
  }

  void _updateScheduleFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      if (data.containsKey('branches')) {
        coachBranches = List<String>.from(data['branches']);
      }

      for (var day in days) {
        schedule[day] = {};
        for (var hour in hours) {
          schedule[day]![hour] = [];
        }
      }

      if (data.containsKey('sessions')) {
        List<dynamic> sessions = data['sessions'] ?? [];

        for (var session in sessions) {
          String branch = session['branch'] ?? '';
          String day = session['day'] ?? '';
          String hour = session['clock'] ?? '';

          if (days.contains(day) && hours.contains(hour)) {
            schedule[day]![hour]?.add({
              'branch': branch,
            });
          }
        }
      }
    }
  }

  Future<void> _fetchStudentsForSession(String day, String hour, String branch) async {
    if (widget.coachId != null) {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('students')
          .where('sessions', arrayContains: {
            'day': day,
            'clock': hour,
            'branch': branch,
          })
          .get();

      setState(() {
        sessionStudents = studentsSnapshot.docs.map((doc) {
          return {
            'name': '${doc['firstName']} ${doc['lastName']}',
            'age': doc['age'],
          };
        }).toList();
      });
    }
  }

  void _onCellTap(String day, String hour) async {
    if (schedule[day]![hour]!.isNotEmpty) {
      String branch = schedule[day]![hour]!.first['branch'] ?? '';
      await _fetchStudentsForSession(day, hour, branch);
    } else if (coachBranches.isNotEmpty) {
      String? selectedBranch = await showDialog<String>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Branş Seç'),
            children: coachBranches.map((branch) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, branch);
                },
                child: Text(branch),
              );
            }).toList(),
          );
        },
      );

      if (selectedBranch != null) {
        setState(() {
          schedule[day]![hour]?.add({
            'branch': selectedBranch,
          });
        });

        _saveSessionToFirestore(day, hour, selectedBranch);
      }
    }
  }

  Future<void> _saveSessionToFirestore(String day, String hour, String branch) async {
    if (widget.coachId != null) {
      final coachRef = FirebaseFirestore.instance.collection('users').doc(widget.coachId);

      await coachRef.update({
        'sessions': FieldValue.arrayUnion([
          {
            'day': day,
            'clock': hour,
            'branch': branch,
          }
        ])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koç Programı'),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _getCoachScheduleStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Veritabanı hatası oluştu.'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                _updateScheduleFromSnapshot(snapshot.data!);

                return Container(
                  height: screenHeight * 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 50),
                          ...days.map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: ListView.builder(
                          itemCount: hours.length,
                          itemBuilder: (context, index) {
                            String hour = hours[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Center(
                                      child: Text(
                                        hour,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  ...days.map((day) {
                                    return Expanded(
                                      child: InkWell(
                                        onTap: () => _onCellTap(day, hour),
                                        borderRadius: BorderRadius.circular(50),
                                        splashColor: Colors.blue.withOpacity(0.3),
                                        child: Container(
                                          margin: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: schedule[day]![hour]?.isNotEmpty == true
                                                ? Colors.green.withOpacity(0.8)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                          width: screenWidth * 0.1,
                                          height: screenWidth * 0.1,
                                          child: Center(
                                            child: Text(
                                              schedule[day]![hour]?.isNotEmpty == true
                                                  ? (schedule[day]![hour]!.first['branch'] ?? '')[0]
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: Text('Program bulunamadı.'));
              }
            },
          ),
          // Seansa kayıtlı öğrenci listesi
          Expanded(
            child: ListView.builder(
              itemCount: sessionStudents.length,
              itemBuilder: (context, index) {
                final student = sessionStudents[index];
                return ListTile(
                  title: Text(student['name']),
                  subtitle: Text('Yaş: ${student['age']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
