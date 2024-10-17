import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/models/student_model.dart';

class CoachStudentsPage extends StatefulWidget {
  final String coachId;
  final String coachName;

  const CoachStudentsPage({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<CoachStudentsPage> createState() => _CoachStudentsPageState();
}

class _CoachStudentsPageState extends State<CoachStudentsPage> {
  Future<void> _togglePaymentStatus(
      String studentId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('students')
          .doc(studentId)
          .update({'paymentStatus': !currentStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme durumu başarıyla güncellendi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ödeme durumu güncellenirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.coachName} - Öğrenciler')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.coachId)
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Hiç öğrenci bulunamadı.'));
          }

          final students = snapshot.data!.docs.map((doc) {
            return Student(
              id: doc.id,
              firstName: doc['firstName'],
              lastName: doc['lastName'],
              age: doc['age'],
              height: (doc['height'] as num).toDouble(),
              weight: (doc['weight'] as num).toDouble(),
              branches: List<String>.from(doc['branches'] ?? []),
              branchExperiences: Map<String, String>.from(
                  doc['branchExperiences'] ?? {}),
              healthProblem: doc['healthProblem'],
              role: doc['role'],
              paymentStatus: doc['paymentStatus'],
              sessions: [], // Eğer sessions varsa eklenebilir
              coachId: widget.coachId,
            );
          }).toList();

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var student = students[index];

              // Ödeme durumuna göre renk belirleme
              final bool paymentStatus = student.paymentStatus ?? false;
              final Color backgroundColor =
                  paymentStatus ? Colors.green[50]! : Colors.red[50]!;

              return Container(
                color: backgroundColor,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${student.firstName[0]}${student.lastName[0]}'),
                  ),
                  title: Text('${student.firstName} ${student.lastName}'),
                  subtitle: Text('Yaş: ${student.age}'),
                  trailing: IconButton(
                    icon: Icon(
                      paymentStatus ? Icons.check : Icons.close,
                      color: paymentStatus ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      _togglePaymentStatus(student.id, paymentStatus);
                    },
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
