import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/admin_session_control_page.dart';
import 'package:sportapp/admin/coach_profile_page.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/student_list_page.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/widgets/custom_appbar.dart';

class CoachListPage extends StatelessWidget {
  const CoachListPage({super.key});

  void _showOptionsDialog(BuildContext context, String coachId, String coachName) { // coachName parametresi ekledik
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.white,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionTile(
                context,
                icon: Icons.list,
                title: 'Öğrenci Listesi',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentListPage(coachId: coachId),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildOptionTile(
                context,
                icon: Icons.person_add,
                title: 'Öğrenci Ekle',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddStudentPage(coachId: coachId),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildOptionTile(
                context,
                icon: Icons.person,
                title: 'Koç Profili',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoachProfilePage(coachId: coachId),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildOptionTile(
                context,
                icon: Icons.check,
                title: 'Yoklama',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RollCallPage(coachId: coachId),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildOptionTile(
                context,
                icon: Icons.settings,
                title: 'Seans Düzenle',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminSessionControlPage(
                        coachId: coachId,
                        coachName: coachName, // Koç adını gönderiyoruz
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: 'Koçlar Listesi',
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
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var coachData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String firstName = coachData['firstName'] ?? '';
              String lastName = coachData['lastName'] ?? '';
              String fullName = '$firstName $lastName'; // Tam adı oluştur

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  tileColor: AppColors.lightBlue,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.blue,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0] : '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.more_vert, color: Colors.grey),
                  onTap: () => _showOptionsDialog(
                    context, 
                    snapshot.data!.docs[index].id,
                    fullName, // Tam adı gönder
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }
}
