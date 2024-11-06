import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/widgets/custom_appbar.dart';

class AdminSessionControlPage extends StatefulWidget {
  final String? coachId;
  final String? coachName; // Yeni eklenen parametre
  const AdminSessionControlPage({super.key, this.coachId, this.coachName});

  @override
  State<AdminSessionControlPage> createState() =>
      _AdminSessionControlPageState();
}

class _AdminSessionControlPageState extends State<AdminSessionControlPage> {
  final List<String> days = ['Pzt', 'Sal', 'Çrş', 'Prş', 'Cum', 'Cmt', 'Pzr'];
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
  List<Map<String, dynamic>> sessionStudents = [];
  String selectedSessionTime = '';
  String selectedSessionDay = '';
  String selectedBranchName = '';

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
      return FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .snapshots();
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
            schedule[day]![hour]?.add({'branch': branch});
          }
        }
      }
    }
  }

  String getBranchInitial(String branch) {
    if (branch.isEmpty) return '';
    return branch[0].toUpperCase();
  }

  Future<void> _fetchStudentsForSession(
      String day, String hour, String branch) async {
    if (widget.coachId != null) {
      setState(() {
        selectedSessionTime = hour;
        selectedSessionDay = day;
        selectedBranchName = branch;
      });

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('students')
          .where('sessions', arrayContains: {
        'day': day,
        'clock': hour,
        'branch': branch,
      }).get();

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

  Future<void> _removeSession(String day, String hour, String branch) async {
    if (widget.coachId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .update({
        'sessions': FieldValue.arrayRemove([
          {'day': day, 'clock': hour, 'branch': branch}
        ])
      });

      setState(() {
        schedule[day]![hour]?.clear();
        sessionStudents.clear();
        selectedSessionDay = '';
        selectedSessionTime = '';
        selectedBranchName = '';
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      String day, String hour, String branch, int studentCount) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Branşı Kaldır'),
          content: Text(studentCount > 0
              ? 'Bu seansta $studentCount öğrenciniz var. Yine de bu branşı kaldırmak istiyor musunuz?'
              : 'Bu branşı kaldırmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                _removeSession(day, hour, branch);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Kaldır'),
            ),
          ],
        );
      },
    );
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
                onPressed: () => Navigator.pop(context, branch),
                child: Text(branch),
              );
            }).toList(),
          );
        },
      );

      if (selectedBranch != null) {
        setState(() {
          schedule[day]![hour]?.add({'branch': selectedBranch});
        });
        await _saveSessionToFirestore(day, hour, selectedBranch);
        await _fetchStudentsForSession(day, hour, selectedBranch);
      }
    }
  }

  Future<void> _onCellLongPress(String day, String hour) async {
    if (schedule[day]![hour]!.isNotEmpty) {
      String branch = schedule[day]![hour]!.first['branch'] ?? '';

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('students')
          .where('sessions', arrayContains: {
        'day': day,
        'clock': hour,
        'branch': branch,
      }).get();

      int studentCount = studentsSnapshot.docs.length;

      _showDeleteConfirmationDialog(day, hour, branch, studentCount);
    }
  }

  Future<void> _saveSessionToFirestore(
      String day, String hour, String branch) async {
    if (widget.coachId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .update({
        'sessions': FieldValue.arrayUnion([
          {'day': day, 'clock': hour, 'branch': branch}
        ])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: '${widget.coachName}\'in Programı',
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
              color: const Color(0xFFE8F1FF),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 50),
                            ...days.map((day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: ListView.builder(
                            itemCount: hours.length,
                            itemBuilder: (context, index) {
                              String hour = hours[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        hour,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    ...days
                                        .map((day) => Expanded(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _onCellTap(day, hour),
                                                onLongPress: () =>
                                                    _onCellLongPress(day, hour),
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: schedule[day]![hour]
                                                                ?.isNotEmpty ==
                                                            true
                                                        ? Colors.blue.shade100
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: selectedSessionDay ==
                                                                day &&
                                                            selectedSessionTime ==
                                                                hour
                                                        ? Border.all(
                                                            color: Colors.blue,
                                                            width: 2)
                                                        : null,
                                                  ),
                                                  height: 40,
                                                  child: Center(
                                                    child: Text(
                                                      schedule[day]![hour]
                                                                  ?.isNotEmpty ==
                                                              true
                                                          ? getBranchInitial(
                                                              schedule[day]![hour]!
                                                                          .first[
                                                                      'branch'] ??
                                                                  '')
                                                          : '',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .blue.shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedBranchName.isNotEmpty
                                ? '$selectedBranchName - $selectedSessionDay $selectedSessionTime'
                                : 'Seans Seçiniz',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: sessionStudents.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Bu seansta kayıtlı öğrenci bulunmamaktadır',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: sessionStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = sessionStudents[index];
                                      // İsim ve soyisimin baş harflerini al
                                      final nameParts =
                                          student['name'].split(' ');
                                      final initials = nameParts.length >= 2
                                          ? '${nameParts[0][0]}${nameParts[1][0]}'
                                              .toUpperCase()
                                          : nameParts[0][0].toUpperCase();

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.white,
                                            child: Text(
                                              initials,
                                              style: TextStyle(
                                                color: AppColors.blue,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            student['name'],
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Program bulunamadı.'));
        },
      ),
    );
  }
}
