import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/student_list_page.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/widgets/custom_appbar.dart';

class AttendantMenu extends StatelessWidget {
  const AttendantMenu({super.key});

  void _showOptionsDialog(BuildContext context, String coachId, String coachName) {
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
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
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var coachData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String firstName = coachData['firstName'] ?? '';
              String lastName = coachData['lastName'] ?? '';
              String fullName = '$firstName $lastName';
              String coachId = snapshot.data!.docs[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showOptionsDialog(
                      context,
                      coachId,
                      fullName,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.blue.withOpacity(0.9),
                          child: Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}