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
  final screenWidth = MediaQuery.of(context).size.width;
  final cellWidth = (screenWidth - 45 - 16) / 7;

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
            '${widget.coachName}\'in Programı',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Antrenman Seansları',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: _getCoachScheduleStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Veritabanı hatası oluştu.'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }

        if (snapshot.hasData) {
          _updateScheduleFromSnapshot(snapshot.data!);

          return Column(
            children: [
              // Takvim Bölümü
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  children: [
                    // Günler Başlığı
                    Row(
                      children: [
                        SizedBox(
                          width: 45,
                          child: Text(
                            'Saat',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...days.map((day) => SizedBox(
                          width: cellWidth,
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Saat Grid'i
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: ListView.builder(
                        itemCount: hours.length,
                        itemBuilder: (context, index) {
                          String hour = hours[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    hour,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                ...days.map((day) => SizedBox(
                                  width: cellWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.all(1),
                                    child: GestureDetector(
                                      onTap: () => _onCellTap(day, hour),
                                      onLongPress: () => _onCellLongPress(day, hour),
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: schedule[day]![hour]?.isNotEmpty == true
                                              ? AppColors.blue.withOpacity(0.1)
                                              : Colors.grey[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: selectedSessionDay == day &&
                                                  selectedSessionTime == hour
                                              ? Border.all(
                                                  color: AppColors.blue,
                                                  width: 2,
                                                )
                                              : Border.all(
                                                  color: Colors.grey[200]!,
                                                  width: 1,
                                                ),
                                        ),
                                        child: Center(
                                          child: schedule[day]![hour]?.isNotEmpty == true
                                              ? Text(
                                                  getBranchInitial(
                                                    schedule[day]![hour]!.first['branch'] ?? '',
                                                  ),
                                                  style: TextStyle(
                                                    color: AppColors.blue,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.add,
                                                  size: 12,
                                                  color: Colors.grey[400],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Öğrenci Listesi Bölümü
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            color: AppColors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedBranchName.isNotEmpty
                                    ? selectedBranchName
                                    : 'Seans Seçiniz',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (selectedSessionDay.isNotEmpty)
                                Text(
                                  '$selectedSessionDay $selectedSessionTime',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: sessionStudents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Bu seansta kayıtlı öğrenci bulunmamaktadır',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: sessionStudents.length,
                                itemBuilder: (context, index) {
                                  final student = sessionStudents[index];
                                  final nameParts = student['name'].split(' ');
                                  final initials = nameParts.length >= 2
                                      ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                                      : nameParts[0][0].toUpperCase();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: AppColors.blue,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        student['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${student['age']} yaşında',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.check_circle,
                                        color: AppColors.blue,
                                        size: 20,
                                      ),
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
          );
        }
        return const Center(child: Text('Program bulunamadı.'));
      },
    ),
  );
}
}
