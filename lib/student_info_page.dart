import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/course_schedule_page.dart';
import 'package:sportapp/models/student_model.dart';

class StudentInfoPage extends StatefulWidget {
  final Student student;

  const StudentInfoPage({super.key, required this.student});

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _healthproblemController;

  bool _paymentStatus = false;

  List<String> _branches = [];
  Map<String, String> _branchExperiences = {};

  final List<String> _experienceLevels = [
    'Deneyimsiz',
    '1-3 yıl',
    '3-5 yıl',
    '5+ yıl'
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.student.firstName);
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _ageController = TextEditingController(text: widget.student.age.toString());
    _heightController =
        TextEditingController(text: widget.student.height.toString());
    _weightController =
        TextEditingController(text: widget.student.weight.toString());
    _healthproblemController =
        TextEditingController(text: widget.student.healthProblem);
    _paymentStatus = widget.student.paymentStatus ?? false;

    // Gelen öğrenci bilgilerinden branşları ve deneyimlerini alıyoruz
    _branches = List.from(widget.student.branches);
    _branchExperiences = Map.from(widget.student.branchExperiences);
  }

  Future<void> _updateStudent() async {
    try {
      // Giriş yapan kullanıcının UID'sini alın
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Kullanıcının 'users' koleksiyonundaki kendi belgesine ve 'students' alt koleksiyonuna erişim
        DocumentReference studentDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid) // Giriş yapan kullanıcının UID'si
            .collection('students')
            .doc(widget.student.id); // Öğrenci belgesinin ID'si

        // Belgenin var olup olmadığını kontrol et
        DocumentSnapshot docSnapshot = await studentDocRef.get();

        if (docSnapshot.exists) {
          // Belge mevcutsa güncelleme yap
          await studentDocRef.update({
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'age': int.tryParse(_ageController.text) ?? widget.student.age,
            'height': double.tryParse(_heightController.text) ??
                widget.student.height,
            'weight': double.tryParse(_weightController.text) ??
                widget.student.weight,
            'branches': _branches,
            'branchExperiences': _branchExperiences,
            'healthProblem': _healthproblemController.text,
            'paymentStatus': _paymentStatus,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Öğrenci bilgileri başarıyla güncellendi')),
          );
        } else {
          // Belge bulunamazsa kullanıcıya hata mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Güncellenmek istenen belge bulunamadı')),
          );
        }
      } else {
        // Kullanıcı giriş yapmamışsa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş yapılmadı!')),
        );
      }
    } catch (e) {
      // Hata durumunda mesaj göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız: $e')),
      );
    }
  }

  void _editBranch(String branch, String experience) {
    TextEditingController branchController =
        TextEditingController(text: branch);
    String selectedExperience = experience;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Branş Düzenle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: branchController,
                    decoration: InputDecoration(labelText: 'Branş'),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedExperience,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedExperience = newValue!;
                      });
                    },
                    items: _experienceLevels
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      int index = _branches.indexOf(branch);
                      _branches[index] = branchController.text;
                      _branchExperiences[branchController.text] =
                          selectedExperience;

                      // Ekranı güncellemek için setState kullanıyoruz
                      // Bu güncelleme anlık olarak kullanıcıya gösterilir
                      this.setState(() {
                        _branchExperiences[branchController.text] =
                            selectedExperience;
                      });

                      if (branch != branchController.text) {
                        _branchExperiences.remove(branch);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğrenci Bilgileri'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CourseSchedulePage(
                            studentName:
                                '${widget.student.firstName} ${widget.student.lastName}',
                            availableBranches: _branches,
                            studentId: widget.student.id,
                          )));
            },
            icon: Icon(Icons.schedule),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Ad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yaş',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Boy (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilo (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Branşlar ve Deneyim Seviyeleri:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                String branch = _branches[index];
                String experience = _branchExperiences[branch] ?? 'Deneyimsiz';

                return ListTile(
                  title: Text(branch),
                  subtitle: Text('Deneyim: $experience'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _editBranch(branch, experience);
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _healthproblemController,
              decoration: InputDecoration(
                labelText: 'Sağlık Sorunu',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ödeme Yapıldı mı?',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _paymentStatus,
                  onChanged: (value) {
                    setState(() {
                      _paymentStatus = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _updateStudent();
                  });
                },
                child: Text('Bilgileri Güncelle'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _healthproblemController.dispose();
    super.dispose();
  }
}
