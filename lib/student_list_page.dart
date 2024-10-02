import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/models/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth için import
import 'student_info_page.dart'; // StudentInfoPage dosyasını eklediğinizi varsayıyorum.

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  User? currentUser; // Giriş yapan kullanıcıyı tutacak

  @override
  void initState() {
    super.initState();
    // Giriş yapan kullanıcıyı alıyoruz
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
      ),
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: Text('Kullanıcı giriş yapmamış'))
            : StreamBuilder<QuerySnapshot>(
                // Giriş yapan kullanıcının 'students' koleksiyonunu sorguluyoruz
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid) // Kullanıcıya özel belge
                    .collection('students') // Öğrencilerin bulunduğu alt koleksiyon
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Bir hata oluştu.'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                          healthProblem: studentData['healthProblem'],
                          role: studentData['role'],
                          paymentStatus: studentData['paymentStatus'],
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                                '${student.firstName[0]}${student.lastName[0]}'),
                          ),
                          title: Text('${student.firstName} ${student.lastName}'),
                          subtitle: Text('Age: ${student.age}'),
                          trailing: Icon(
                            student.paymentStatus ?? false
                                ? Icons.check
                                : Icons.close,
                            color: student.paymentStatus ?? false
                                ? Colors.green
                                : Colors.red,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentInfoPage(student: student),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('Öğrenci bulunamadı.'));
                  }
                },
              ),
      ),
    );
  }
}
