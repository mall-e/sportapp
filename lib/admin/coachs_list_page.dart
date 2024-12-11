import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/admin_session_control_page.dart';
import 'package:sportapp/admin/coach_profile_page.dart';
import 'package:sportapp/payment_screen.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/student_list_page.dart';
import 'package:sportapp/widgets/colors.dart';

class CoachListPage extends StatelessWidget {
  const CoachListPage({super.key});

  void _showOptionsDialog(
      BuildContext context, String coachId, String coachName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.blue.withOpacity(0.1),
                          child: Text(
                            coachName[0].toUpperCase(),
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coachName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Koç İşlemleri',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildOptionGrid(context, coachId, coachName),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionGrid(
      BuildContext context, String coachId, String coachName) {
    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.list,
        'color': Colors.blue,
        'title': 'Öğrenci Listesi',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentListPage(coachId: coachId),
            ),
          );
        },
      },
      {
        'icon': Icons.person_add,
        'color': Colors.green,
        'title': 'Öğrenci Ekle',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStudentPage(coachId: coachId),
            ),
          );
        },
      },
      {
        'icon': Icons.person,
        'color': Colors.purple,
        'title': 'Koç Profili',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoachProfilePage(coachId: coachId),
            ),
          );
        },
      },
      {
        'icon': Icons.check_circle,
        'color': Colors.orange,
        'title': 'Yoklama',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RollCallPage(coachId: coachId),
            ),
          );
        },
      },
      {
        'icon': Icons.settings,
        'color': Colors.teal,
        'title': 'Seans Düzenle',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminSessionControlPage(
                coachId: coachId,
                coachName: coachName,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.payment,
        'color': const Color.fromARGB(255, 221, 221, 100),
        'title': 'Ödeme Kontrolü',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonthlyPaymentScreen(
                coachId: coachId,
              ),
            ),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return InkWell(
          onTap: () {
            Navigator.pop(context);
            option['onTap']();
          },
          child: Container(
            decoration: BoxDecoration(
              color: (option['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option['icon'] as IconData,
                  color: option['color'] as Color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  option['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Koçlar Listesi',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tüm koçları yönetin',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Bir hata oluştu.'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz koç bulunmuyor.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var coachData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String firstName = coachData['firstName'] ?? '';
              String lastName = coachData['lastName'] ?? '';
              String fullName = '$firstName $lastName';
              String coachId = snapshot.data!.docs[index].id;

              return Dismissible(
                key: Key(coachId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text('$fullName Silinecek'),
                        content: const Text(
                          'Bu koç ve tüm ilgili verileri silinecektir. Bu işlem geri alınamaz!\n\nDevam etmek istiyor musunuz?',
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
                  // Mevcut silme işlemi kodunu koru
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_forever, color: Colors.white, size: 32),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          _showOptionsDialog(context, coachId, fullName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  firstName.isNotEmpty
                                      ? firstName[0].toUpperCase()
                                      : '',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Koç',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                            ),
                          ],
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
