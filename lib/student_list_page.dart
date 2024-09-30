import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/models/student_model.dart';
import 'student_info_page.dart'; // StudentInfoPage dosyasını eklediğinizi varsayıyorum.

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student List'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var studentData = snapshot.data!.docs[index];

                  // Student nesnesini oluşturma
                  Student student = Student(
                    id: studentData.id,
                    firstName: studentData['firstName'],
                    lastName: studentData['lastName'],
                    age: studentData['age'],
                    height: studentData['height'].toDouble(),
                    weight: studentData['weight'].toDouble(),
                    branch: studentData['branch'],
                    paymentStatus: studentData['paymentStatus'],  // Ödeme durumu eklendi
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${student.firstName[0]}${student.lastName[0]}'),
                    ),
                    title: Text('${student.firstName} ${student.lastName}'),
                    subtitle: Text('Age: ${student.age}'),
                    trailing: Icon(
                      student.paymentStatus ? Icons.check : Icons.close,
                      color: student.paymentStatus ? Colors.green : Colors.red,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentInfoPage(student: student),
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              return Center(child: Text('No students found'));
            }
          },
        ),
      ),
    );
  }
}
