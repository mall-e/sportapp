import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportapp/widgets/colors.dart';

class CoachsProgramPage extends StatefulWidget {
  final bool showBackButton; 
  const CoachsProgramPage({super.key,this.showBackButton = false,});

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

  

    Widget _buildScheduleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 60,
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
          ...days.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String hour, List<String> days) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                hour,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          ...days.map((day) {
            final hasSession = schedule[day]?[hour]?.isNotEmpty ?? false;
            return Expanded(
              child: InkWell(
                onTap: hasSession ? () => _loadSessionStudents(day, hour) : null,
                child: Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasSession ? AppColors.lightBlue : Colors.grey[100],
                    border: Border.all(
                      color: hasSession ? AppColors.blue : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      schedule[day]?[hour]?['initial'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasSession ? AppColors.blue : Colors.grey[400],
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
  }

  Widget _buildStudentList() {
    if (selectedSessionStudents.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (selectedSessionInfo != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.sports, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selectedSessionInfo!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: selectedSessionStudents.length,
              itemBuilder: (context, index) {
                final student = selectedSessionStudents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightBlue,
                      backgroundImage: student['profilePicUrl'] != null
                          ? NetworkImage(student['profilePicUrl'])
                          : null,
                      child: student['profilePicUrl'] == null
                          ? Text(
                              '${student['firstName'][0]}${student['lastName'][0]}'.toUpperCase(),
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      '${student['firstName']} ${student['lastName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Boy: ${student['height'] ?? 'Girilmemiş'} cm, '
                      'Kilo: ${student['weight'] ?? 'Girilmemiş'} kg',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: widget.showBackButton ? IconButton( // Koşula bağlı leading
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
      title: const Text(
        'Antrenör Programı',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: _getCoachScheduleStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Bir hata oluştu',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }

        if (snapshot.hasData) {
          _updateScheduleFromSnapshot(snapshot.data!);

          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: selectedSessionStudents.isNotEmpty ? 100 : 0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildScheduleHeader(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: hours
                                      .map((hour) => _buildTimeSlot(hour, days))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedSessionStudents.isNotEmpty)
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.15,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          if (selectedSessionInfo != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.sports, color: AppColors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedSessionInfo!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: selectedSessionStudents.length,
                              itemBuilder: (context, index) {
                                final student = selectedSessionStudents[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.lightBlue,
                                      backgroundImage: student['profilePicUrl'] != null
                                          ? NetworkImage(student['profilePicUrl'])
                                          : null,
                                      child: student['profilePicUrl'] == null
                                          ? Text(
                                              '${student['firstName'][0]}${student['lastName'][0]}'.toUpperCase(),
                                              style: TextStyle(
                                                color: AppColors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      '${student['firstName']} ${student['lastName']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Boy: ${student['height'] ?? 'Girilmemiş'} cm, '
                                      'Kilo: ${student['weight'] ?? 'Girilmemiş'} kg',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        }

        return Center(
          child: Text(
            'Program bulunamadı',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      },
    ),
  );
}
}