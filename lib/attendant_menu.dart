import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/widgets/custom_appbar.dart';
import 'coach_students_page.dart'; // Öğrenci sayfası için import

class AttendantMenu extends StatefulWidget {
  const AttendantMenu({super.key});

  @override
  State<AttendantMenu> createState() => _AttendantMenuState();
}

class _AttendantMenuState extends State<AttendantMenu> {
  Future<List<Map<String, dynamic>>> _getCoaches() async {
    List<Map<String, dynamic>> coachList = [];

    try {
      QuerySnapshot coachesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .get();

      for (var coachDoc in coachesSnapshot.docs) {
        coachList.add({
          'coachId': coachDoc.id,
          'coachName': coachDoc['firstName'], // Koç ismi
        });
      }
    } catch (e) {
      print('Error fetching coaches: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hocalar getirilirken bir hata oluştu: $e')),
      );
    }

    return coachList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: 'Görevli Ekranı'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCoaches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hiç koç bulunamadı.'));
          }

          final coachList = snapshot.data!;

          return ListView.builder(
            itemCount: coachList.length,
            itemBuilder: (context, index) {
              var coachData = coachList[index];

              return ListTile(
                title: Text(coachData['coachName']),
                onTap: () {
                  // Öğrenci sayfasına yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoachStudentsPage(
                        coachId: coachData['coachId'],
                        coachName: coachData['coachName'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
