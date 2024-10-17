import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/coach_profile_page.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/student_list_page.dart';

class CoachListPage extends StatelessWidget {
  final int whichCase; // Parametre ekliyoruz

  const CoachListPage(
      {super.key,
      required this.whichCase}); // Parametreyi constructor'a ekliyoruz

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

              return ListTile(
                leading: CircleAvatar(
                  child: Text('${coachData['firstName'][0]}'),
                ),
                title: Text('${coachData['firstName']}'),
                onTap: () {
                  // Eğer showStudentList parametresi true ise öğrenci listesine git
                  // false ise koçun profiline git
                  switch (whichCase) {
                    case 0:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentListPage(coachId: coachData.id),
                        ),
                      );
                      break;
                    case 1:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoachProfilePage(
                              coachId: coachData.id), // Koç profil sayfası
                        ),
                      );
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RollCallPage(
                              coachId: coachData.id), // Koç profil sayfası
                        ),
                      );
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddStudentPage(
                              coachId: coachData.id), // Koç profil sayfası
                        ),
                      );
                      break;
                    default:
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
