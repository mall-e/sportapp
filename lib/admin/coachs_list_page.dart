import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/admin_session_control_page.dart';
import 'package:sportapp/admin/coach_profile_page.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/student_list_page.dart';

class CoachListPage extends StatelessWidget {
  const CoachListPage({super.key});

  void _showOptionsDialog(BuildContext context, String coachId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Öğrenci Listesi'),
              onTap: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentListPage(coachId: coachId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Öğrenci Ekle'),
              onTap: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStudentPage(coachId: coachId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Koç Profili'),
              onTap: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoachProfilePage(coachId: coachId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Yoklama'),
              onTap: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RollCallPage(coachId: coachId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Seans Düzenle'),
              onTap: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminSessionControlPage(coachId: coachId),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koçlar Listesi'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Koç bulunamadı.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var coachData = snapshot.data!.docs[index];
              var coachName = coachData['firstName'];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(coachName[0]),
                ),
                title: Text(coachName),
                onTap: () => _showOptionsDialog(context, coachData.id),
              );
            },
          );
        },
      ),
    );
  }
}
