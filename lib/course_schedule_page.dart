import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseSchedulePage extends StatefulWidget {
  final String studentName;
  final List<String> availableBranches;
  final String studentId;
  final String? coachId;

  const CourseSchedulePage({
    super.key,
    required this.studentName,
    required this.availableBranches,
    required this.studentId,
    this.coachId,
  });

  @override
  State<CourseSchedulePage> createState() => _CourseSchedulePageState();
}

class _CourseSchedulePageState extends State<CourseSchedulePage> {
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

  Map<String, Map<String, String?>> schedule = {};
  List<dynamic> studentSessions = [];

  @override
  void initState() {
    super.initState();
    // Tüm hücreler boş olacak şekilde matris oluştur
    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = null;
      }
    }
    _fetchStudentSessions();
  }

  Future<void> _fetchStudentSessions() async {
    try {
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId ?? FirebaseAuth.instance.currentUser?.uid)
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentSnapshot.exists) {
        // sessions alanı var mı kontrol et
        if (studentSnapshot.data() != null &&
            (studentSnapshot.data() as Map<String, dynamic>)
                .containsKey('sessions')) {
          setState(() {
            studentSessions = studentSnapshot.get('sessions') ?? [];
          });
        } else {
          // sessions alanı yoksa boş bir liste olarak ekle
          await studentSnapshot.reference
              .set({'sessions': []}, SetOptions(merge: true));
          setState(() {
            studentSessions = [];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Öğrenci verileri yüklenirken hata oluştu: $e")),
      );
    }
  }

  Future<void> toggleSession(String day, String hour, String branch) async {
    try {
      DocumentReference studentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId ?? FirebaseAuth.instance.currentUser?.uid)
          .collection('students')
          .doc(widget.studentId);

      DocumentSnapshot studentSnapshot = await studentRef.get();
      List<dynamic> sessions = [];

      if (studentSnapshot.exists) {
        if (studentSnapshot.data() != null &&
            (studentSnapshot.data() as Map<String, dynamic>)
                .containsKey('sessions')) {
          sessions = studentSnapshot.get('sessions') ?? [];
        } else {
          await studentRef.set({'sessions': []}, SetOptions(merge: true));
        }
      }

      Map<String, String> sessionData = {
        'day': day,
        'clock': hour,
        'branch': branch
      };
      bool sessionExists = sessions.any((session) =>
          session['day'] == day &&
          session['clock'] == hour &&
          session['branch'] == branch);

      if (sessionExists) {
        sessions.removeWhere((session) =>
            session['day'] == day &&
            session['clock'] == hour &&
            session['branch'] == branch);
        await studentRef.update({'sessions': sessions});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Oturum çıkarıldı: $day $hour $branch")),
        );
      } else {
        sessions.add(sessionData);
        await studentRef.update({'sessions': sessions});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Oturum eklendi: $day $hour $branch")),
        );
      }

      // Öğrenci oturumları güncellendiğinde yeniden yükle
      _fetchStudentSessions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Oturum güncellenirken hata oluştu: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} için Ders Programı'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.coachId ?? FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            List<dynamic> sessions = snapshot.data!.get('sessions') ?? [];

            // Veriyi tabloya sıfırlıyoruz ve yeni veriyi tabloya uygun şekilde ayarlıyoruz
            for (var day in days) {
              for (var hour in hours) {
                schedule[day]![hour] = null;
              }
            }
            for (var session in sessions) {
              String branch = session['branch'] ?? '';
              String day = session['day'] ?? '';
              String hour = session['clock'] ?? '';

              if (day.isNotEmpty && hour.isNotEmpty) {
                schedule[day]?[hour] = branch;
              }
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(color: Colors.blue),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      children: [
                        const SizedBox.shrink(),
                        ...days.map((day) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      ],
                    ),
                    ...hours.map((hour) {
                      return TableRow(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(hour),
                            ),
                          ),
                          ...days.map((day) {
                            String? branch = schedule[day]![hour];
                            Color cellColor;

                            if (branch != null) {
                              // Öğrenci bu oturumu eklemiş mi?
                              bool studentHasSession = studentSessions.any(
                                  (session) =>
                                      session['day'] == day &&
                                      session['clock'] == hour &&
                                      session['branch'] == branch);

                              // Eğer öğrenciye aitse yeşil, değilse koç oturumu olarak sarı
                              if (studentHasSession) {
                                cellColor = Colors.green.withOpacity(0.3);
                              } else if (widget.availableBranches
                                  .contains(branch)) {
                                cellColor = Colors.yellow.withOpacity(0.3);
                              } else {
                                // Koçun branşı öğrencinin branşları arasında yoksa kırmızı
                                cellColor = Colors.red.withOpacity(0.3);
                              }
                            } else {
                              cellColor = Colors.grey.withOpacity(0.2);
                            }

                            return GestureDetector(
                              onTap: branch != null
                                  ? () {
                                      // Eğer branş öğrenci için uygun değilse uyarı ver
                                      if (!widget.availableBranches
                                          .contains(branch)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Uygun branşınız değildir")),
                                        );
                                      } else {
                                        // Branş uygunsa oturumu ekle veya çıkar
                                        toggleSession(day, hour, branch);
                                      }
                                    }
                                  : null,
                              child: Container(
                                height: 60,
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: cellColor,
                                ),
                                child: Center(
                                  child: Text(branch ?? '-'),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
