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
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var coachData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String firstName = coachData['firstName'] ?? '';
            String lastName = coachData['lastName'] ?? '';
            String fullName = '$firstName $lastName';
            String coachId = snapshot.data!.docs[index].id;

            return Dismissible(
              key: Key(coachId),
              direction: DismissDirection.endToStart, // Sadece sağdan sola kaydırma
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('$fullName Silinecek'),
                      content: const Text(
                        'Bu koç ve tüm ilgili verileri (öğrenciler, yoklamalar, seanslar vb.) kalıcı olarak silinecektir. Bu işlem geri alınamaz!\n\nDevam etmek istiyor musunuz?',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('İptal'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Sil'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) async {
                try {
                  // Yükleme göstergesi
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );

                  // 1. Koçun öğrencilerini silme
                  final studentsSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(coachId)
                      .collection('students')
                      .get();
                  
                  for (var doc in studentsSnapshot.docs) {
                    await doc.reference.delete();
                  }

                  // 2. Yoklama verilerini silme
                  final rollCallSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(coachId)
                      .collection('rollcall')
                      .get();

                  for (var rollCallDoc in rollCallSnapshot.docs) {
                    await rollCallDoc.reference.delete();
                  }

                  // 3. Koçun kendisini silme
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(coachId)
                      .delete();

                  // Yükleme göstergesini kapat
                  Navigator.of(context).pop();

                  // Başarılı mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$fullName başarıyla silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Yükleme göstergesini kapat
                  Navigator.of(context).pop();
                  
                  // Hata mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Silme işlemi sırasında hata oluştu: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 32,
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
