import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoachsProgramPage extends StatefulWidget {
  const CoachsProgramPage({super.key});

  @override
  State<CoachsProgramPage> createState() => _CoachsProgramPageState();
}

class _CoachsProgramPageState extends State<CoachsProgramPage> {
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

  Map<String, Map<String, Map<String, String>>> schedule = {};
  List<Map<String, dynamic>> selectedSessionStudents = [];
  String? selectedSessionInfo;

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
  }

  void _initializeSchedule() {
    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = {};
      }
    }
  }

  Stream<DocumentSnapshot> _getCoachScheduleStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots();
    }
    return const Stream.empty();
  }

  void _updateScheduleFromSnapshot(DocumentSnapshot snapshot) {
    _initializeSchedule();

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey('sessions')) {
      List<dynamic> sessions = data['sessions'] ?? [];

      for (var session in sessions) {
        String branch = session['branch'] ?? '';
        String day = session['day'] ?? '';
        String hour = session['clock'] ?? '';

        if (days.contains(day) && hours.contains(hour)) {
          schedule[day]![hour] = {
            'branch': branch,
            'initial': branch.isNotEmpty ? branch[0].toUpperCase() : '',
          };
        }
      }
    }
  }

  Future<void> _loadSessionStudents(String day, String hour) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? branch = schedule[day]?[hour]?['branch'];
    if (branch == null) return;

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('students')
          .where('sessions', arrayContainsAny: [
        {'day': day, 'clock': hour, 'branch': branch}
      ]).get();

      setState(() {
        selectedSessionStudents = studentsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'firstName': data['firstName'] ?? '',
                'lastName': data['lastName'] ?? '',
                'profilePicUrl': data['profilePicUrl'],
                'weight': data['weight'],
                'height': data['height'],
              };
            })
            .toList();
        selectedSessionInfo = '$branch - $day $hour';
      });
    } catch (e) {
      print('Öğrenci listesi yüklenirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenör Programı'),
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
                                    final hasSession = schedule[day]?[hour]?.isNotEmpty ?? false;
                                    return Expanded(
                                      child: InkWell(
                                        onTap: hasSession
                                            ? () => _loadSessionStudents(day, hour)
                                            : null,
                                        borderRadius: BorderRadius.circular(50),
                                        splashColor: Colors.blue.withOpacity(0.3),
                                        child: Container(
                                          margin: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: hasSession
                                                ? Colors.blue.withOpacity(0.8)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                          width: screenWidth * 0.1,
                                          height: screenWidth * 0.1,
                                          child: Center(
                                            child: Text(
                                              schedule[day]?[hour]?['initial'] ?? '',
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
              }
              return const Center(child: Text('Program bulunamadı.'));
            },
          ),
          if (selectedSessionStudents.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Ders: ${selectedSessionInfo ?? ""}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedSessionStudents.length,
                      itemBuilder: (context, index) {
                        final student = selectedSessionStudents[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              backgroundImage: student['profilePicUrl'] != null
                                  ? NetworkImage(student['profilePicUrl'])
                                  : null,
                              child: student['profilePicUrl'] == null
                                  ? Text(
                                      '${student['firstName'][0]}${student['lastName'][0]}'.toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            title: Text(
                              '${student['firstName']} ${student['lastName']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Boy: ${student['height'] ?? 'Girilmemiş'} cm, '
                              'Kilo: ${student['weight'] ?? 'Girilmemiş'} kg',
                            ),
                          ),
                        );
                      },
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