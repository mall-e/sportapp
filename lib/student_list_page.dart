import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/widgets/custom_appbar.dart';
import 'settings_page.dart';
import 'student_info_page.dart';
import 'models/student_model.dart';

class StudentListPage extends StatefulWidget {
  final String? coachId;

  const StudentListPage({super.key, this.coachId});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _deleteStudent(String studentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId ?? currentUser!.uid)
          .collection('students')
          .doc(studentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci başarıyla silindi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğrenci silinirken bir hata oluştu: $e')),
      );
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Silme işlemi'),
          content: const Text('Bu öğrenciyi silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: 'Öğrenciler Listesi',
      ),
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: Text('Kullanıcı giriş yapmamış'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.coachId ?? currentUser!.uid)
                    .collection('students')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Bir hata oluştu.'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Öğrenci bulunamadı.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var studentData = snapshot.data!.docs[index];

                      List<Map<String, String>> sessions = [];
                      if (studentData.data() != null &&
                          (studentData.data() as Map<String, dynamic>)
                              .containsKey('sessions') &&
                          studentData['sessions'] != null) {
                        sessions = List<Map<String, String>>.from(
                          (studentData['sessions'] as List<dynamic>).map(
                            (session) => Map<String, String>.from(
                                session as Map<String, dynamic>),
                          ),
                        );
                      }

                      Student student = Student(
                        id: studentData.id,
                        firstName: studentData['firstName'],
                        lastName: studentData['lastName'],
                        age: studentData['age'],
                        height: (studentData['height'] as num).toDouble(),
                        weight: (studentData['weight'] as num).toDouble(),
                        branches:
                            List<String>.from(studentData['branches'] ?? []),
                        branchExperiences: Map<String, String>.from(
                            studentData['branchExperiences'] ?? {}),
                        healthProblem: studentData['healthProblem'],
                        role: studentData['role'],
                        paymentStatus: studentData['paymentStatus'],
                        sessions: sessions,
                        coachId: studentData['coachId'],
                      );

                      return Dismissible(
                        key: Key(student.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final bool? confirmed = await _confirmDelete(context);
                          return confirmed;
                        },
                        onDismissed: (direction) {
                          _deleteStudent(student.id);
                        },
                        child: Card(
                          color: AppColors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12.0),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.blue,
                              child: Text(
                                '${student.firstName[0]}${student.lastName[0]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${student.firstName} ${student.lastName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('Yaş: ${student.age}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentInfoPage(
                                    student: student,
                                    coachId: widget.coachId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
