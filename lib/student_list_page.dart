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
  final bool showBackButton;

  const StudentListPage({super.key, this.coachId, this.showBackButton = false});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  User? currentUser;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton ? IconButton( // Koşula bağlı leading
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        title: const Text(
          'Öğrenciler Listesi',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Öğrenci Ara',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          Expanded(
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

                      var filteredDocs = snapshot.data!.docs.where((doc) {
                        final student = doc.data() as Map<String, dynamic>;
                        final fullName =
                            '${student['firstName']} ${student['lastName']}'
                                .toLowerCase();
                        return fullName.contains(searchQuery);
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var studentData = filteredDocs[index];
                          Student student = Student(
                            id: studentData.id,
                            firstName: studentData['firstName'],
                            lastName: studentData['lastName'],
                            age: studentData['age'],
                            height: (studentData['height'] as num).toDouble(),
                            weight: (studentData['weight'] as num).toDouble(),
                            branches: List<String>.from(
                                studentData['branches'] ?? []),
                            branchExperiences: Map<String, String>.from(
                                studentData['branchExperiences'] ?? {}),
                            healthProblem: studentData['healthProblem'],
                            role: studentData['role'],
                            paymentStatus: studentData['paymentStatus'],
                            sessions: [],
                            coachId: studentData['coachId'],
                          );

                          return Dismissible(
                            key: Key(student.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              final confirmed = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Öğrenci Silme'),
                                  content: Text(
                                      '${student.firstName} ${student.lastName} isimli öğrenciyi silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                        'Sil',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              return confirmed;
                            },
                            onDismissed: (direction) {
                              _deleteStudent(student.id);
                            },
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Sil',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.lightBlue,
                                  child: Text(
                                    '${student.firstName[0]}${student.lastName[0]}',
                                    style: const TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${student.firstName} ${student.lastName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Yaş: ${student.age}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios,
                                    color: Colors.grey),
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
        ],
      ),
    );
  }
}
