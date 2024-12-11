import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportapp/widgets/colors.dart';

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
    '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00',
  ];

  Map<String, Map<String, String?>> schedule = {};
  List<dynamic> studentSessions = [];

  @override
  void initState() {
    super.initState();
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
        if (studentSnapshot.data() != null &&
            (studentSnapshot.data() as Map<String, dynamic>).containsKey('sessions')) {
          setState(() {
            studentSessions = studentSnapshot.get('sessions') ?? [];
          });
        } else {
          await studentSnapshot.reference.set({'sessions': []}, SetOptions(merge: true));
          setState(() {
            studentSessions = [];
          });
        }
      }
    } catch (e) {
      _showSnackBar("Öğrenci verileri yüklenirken hata oluştu: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
            (studentSnapshot.data() as Map<String, dynamic>).containsKey('sessions')) {
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
        _showSnackBar("Oturum çıkarıldı: $day $hour $branch");
      } else {
        sessions.add(sessionData);
        await studentRef.update({'sessions': sessions});
        _showSnackBar("Oturum eklendi: $day $hour $branch");
      }

      _fetchStudentSessions();
    } catch (e) {
      _showSnackBar("Oturum güncellenirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ders Programı',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.studentName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.coachId ?? FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Bir hata oluştu: ${snapshot.error}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            List<dynamic> sessions = snapshot.data!.get('sessions') ?? [];

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header Row
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: Text(
                                      'Saat',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                ...days.map((day) => SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Time slots
                          ...hours.map((hour) => Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 60,
                                  child: Center(
                                    child: Text(
                                      hour,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                ...days.map((day) {
                                  String? branch = schedule[day]![hour];
                                  bool studentHasSession = studentSessions.any(
                                    (session) =>
                                      session['day'] == day &&
                                      session['clock'] == hour &&
                                      session['branch'] == branch
                                  );
                                  
                                  Color cellColor = Colors.transparent;
                                  if (branch != null) {
                                    if (studentHasSession) {
                                      cellColor = AppColors.blue.withOpacity(0.1);
                                    } else if (widget.availableBranches.contains(branch)) {
                                      cellColor = Colors.amber.withOpacity(0.1);
                                    } else {
                                      cellColor = Colors.red.withOpacity(0.1);
                                    }
                                  }

                                  return SizedBox(
                                    width: 80,
                                    height: 60,
                                    child: GestureDetector(
                                      onTap: branch != null ? () {
                                        if (!widget.availableBranches.contains(branch)) {
                                          _showSnackBar("Bu branş sizin için uygun değil");
                                        } else {
                                          toggleSession(day, hour, branch);
                                        }
                                      } : null,
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: cellColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: branch != null ? 
                                              (studentHasSession ? AppColors.blue : Colors.grey[300]!) :
                                              Colors.grey[200]!,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            branch ?? '-',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: branch != null ?
                                                (studentHasSession ? AppColors.blue : Colors.grey[600]) :
                                                Colors.grey[400],
                                              fontWeight: studentHasSession ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Mevcut Seanslarınız', AppColors.blue.withOpacity(0.1), AppColors.blue),
                        const SizedBox(width: 16),
                        _buildLegendItem('Müsait Seanslar', Colors.amber.withOpacity(0.1), Colors.grey[600]!),
                        const SizedBox(width: 16),
                        _buildLegendItem('Uygun Olmayan', Colors.red.withOpacity(0.1), Colors.grey[600]!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color backgroundColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: textColor.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}