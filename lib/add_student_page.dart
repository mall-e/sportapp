import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sportapp/models/student_model.dart';

class AddStudentPage extends StatefulWidget {
  final String? coachId;
  const AddStudentPage({super.key, this.coachId});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  File? _imageFile;
  List<Map<String, String>> _branchExperiencePairs = []; // Branş ve deneyim listesi
  List<Map<String, String>> _sessions = []; // Sessions listesi

  Future<void> _pickImage() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    if (await Permission.camera.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadImageToFirebase(_imageFile!);
      }
    } else {
      print('Kamera izni verilmedi');
    }
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('students/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      print('Image uploaded to Firebase Storage');
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrenci Ekle"),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExistingStudentsPage(coachId: widget.coachId ?? ''),
                ),
              );
            },
            tooltip: "Var Olan Öğrencileri Görüntüle",
          ),
        ],
      ),
        body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? Icon(Icons.person) : null,
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: AddStudentInformation(
                  onBranchExperienceAdded: (branch, experience) {
                    setState(() {
                      _branchExperiencePairs.add({
                        'branch': branch,
                        'experience': experience
                      });

                      // Yeni session ekle
                      _sessions.add({
                        'branch': branch,
                        'clock': '',
                        'day': '',
                      });
                    });
                  },
                  branchExperiencePairs: _branchExperiencePairs,
                  sessions: _sessions,
                  coachId: widget.coachId,
                  )), // Sessions listesi gönderiliyor
        ],
      ),
    ));
  }
}

class AddStudentInformation extends StatefulWidget {
  final Function(String, String) onBranchExperienceAdded; // Branş ve deneyim ekleme fonksiyonu
  final List<Map<String, String>> branchExperiencePairs; // Branş ve deneyim listesi
  final List<Map<String, String>> sessions; // Branş ve session bilgilerini içeren liste
  final String? coachId;

  const AddStudentInformation({
    super.key,
    required this.onBranchExperienceAdded,
    required this.branchExperiencePairs,
    required this.sessions, this.coachId,
  });

  @override
  State<AddStudentInformation> createState() => _AddStudentInformationState();
}

class _AddStudentInformationState extends State<AddStudentInformation> {
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _branchController = TextEditingController();
  TextEditingController _healthproblemController = TextEditingController();
  bool _paymentStatus = false;

  String _selectedExperience = 'Deneyimsiz'; // Deneyim seviyesinin varsayılan değeri

  final List<String> experienceLevels = [
    'Deneyimsiz',
    '1-3 yıl',
    '3-5 yıl',
    '5+ yıl'
  ]; // Deneyim seviyesi listesi

  void addStudent() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapılmadı!')),
      );
      return;
    }

    String coachId = widget.coachId ?? currentUser.uid; // Aktif kullanıcının UID'si

    Student student = Student(
      id: '',
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      age: int.tryParse(_ageController.text) ?? 0,
      height: double.tryParse(_heightController.text) ?? 0.0,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      branches: widget.branchExperiencePairs.map((pair) => pair['branch']!).toList(),
      branchExperiences: Map.fromIterable(widget.branchExperiencePairs,
          key: (pair) => pair['branch']!, value: (pair) => pair['experience']!),
      healthProblem: _healthproblemController.text,
      role: 'student',
      paymentStatus: _paymentStatus,
      sessions: widget.sessions, // Sessions listesi eklendi
      coachId: coachId, // Koçun ID'si buraya atanıyor
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(coachId)
          .collection('students')
          .add(student.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci başarıyla eklendi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğrenci eklenirken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: ListView(
        children: [
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Ad',
            ),
          ),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Soyad',
            ),
          ),
          TextField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Yaş',
            ),
          ),
          TextField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: 'Boy',
            ),
          ),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Kilo',
            ),
          ),
          TextField(
            controller: _healthproblemController,
            decoration: InputDecoration(
              labelText: 'Sağlık sorunu',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _branchController,
                  decoration: InputDecoration(
                    labelText: 'Branş',
                  ),
                ),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedExperience,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedExperience = newValue!;
                    });
                  },
                  items: experienceLevels
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_branchController.text.isNotEmpty &&
                      _selectedExperience.isNotEmpty) {
                    widget.onBranchExperienceAdded(
                        _branchController.text, _selectedExperience);
                    _branchController.clear();
                    _selectedExperience = 'Deneyimsiz'; // Varsayılanı geri yükle
                  }
                },
                child: Text('Ekle'),
              ),
            ],
          ),
          // ListView ile eklenen branş ve deneyim seviyelerini göster
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.branchExperiencePairs.length,
            itemBuilder: (context, index) {
              final pair = widget.branchExperiencePairs[index];
              return ListTile(
                title: Text(pair['branch']!),
                subtitle: Text('Deneyim: ${pair['experience']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      widget.branchExperiencePairs.removeAt(index);
                      widget.sessions.removeAt(index); // Sessions listesinden de kaldır
                    });
                  },
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: addStudent,
            child: Text('Öğrenciyi Ekle'),
          ),
        ],
      ),
    );
  }
}

class ExistingStudentsPage extends StatefulWidget {
  final String coachId;

  const ExistingStudentsPage({Key? key, required this.coachId}) : super(key: key);

  @override
  _ExistingStudentsPageState createState() => _ExistingStudentsPageState();
}

class _ExistingStudentsPageState extends State<ExistingStudentsPage> {
  List<String> coachBranches = [];

  Future<void> _getCoachBranches() async {
    // Koçun branşlarını çek
    DocumentSnapshot coachDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.coachId)
        .get();

    if (coachDoc.exists) {
      coachBranches = List<String>.from(coachDoc.get('branches') ?? []);
    }
  }

  Future<List<Student>> _getFilteredStudents() async {
    List<Student> filteredStudents = [];
    
    // Tüm koçları getir
    QuerySnapshot coachesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'coach')  // Sadece koçları getir
        .get();

    // Her koçun öğrencilerini kontrol et
    for (var coach in coachesSnapshot.docs) {
      // Eğer bu bizim giriş yapan koçumuz ise, atla
      if (coach.id == widget.coachId) {
        continue;
      }

      QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(coach.id)
          .collection('students')
          .get();

      // Öğrencileri filtreleyerek listeye ekle
      for (var studentDoc in studentsSnapshot.docs) {
        Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;
        Student student = Student.fromMap(data);
        student.id = studentDoc.id;
        student.originalCoachId = coach.id;
        
        // Öğrencinin branşlarından en az biri, koçun branşlarından biriyle eşleşiyorsa ekle
        List<String> studentBranches = List<String>.from(data['branches'] ?? []);
        if (studentBranches.any((branch) => coachBranches.contains(branch))) {
          filteredStudents.add(student);
        }
      }
    }

    return filteredStudents;
  }

  Future<bool> _isStudentAlreadyAdded(String studentId) async {
    final existingStudent = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.coachId)
        .collection('students')
        .where('originalId', isEqualTo: studentId)  // originalId ile kontrol et
        .get();

    return existingStudent.docs.isNotEmpty;
  }

  Future<void> _addStudentToCoach(BuildContext context, Student student) async {
    try {
      if (await _isStudentAlreadyAdded(student.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu öğrenci zaten eklenmiş.')),
        );
        return;
      }

      // Öğrenciyi eklerken originalId'sini de kaydet
      Map<String, dynamic> studentData = student.toMap();
      studentData['originalId'] = student.id;  // Orijinal ID'yi sakla
      studentData['originalCoachId'] = student.originalCoachId;  // Orijinal koç ID'sini sakla

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('students')
          .add(studentData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğrenci başarıyla eklendi!')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğrenci eklenirken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diğer Koçların Öğrencileri'),
      ),
      body: FutureBuilder(
        future: _getCoachBranches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          return FutureBuilder<List<Student>>(
            future: _getFilteredStudents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              final students = snapshot.data ?? [];

              if (students.isEmpty) {
                return Center(
                  child: Text('Uygun branşlarda öğrenci bulunamadı.'),
                );
              }

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];

                  return FutureBuilder<bool>(
                    future: _isStudentAlreadyAdded(student.id),
                    builder: (context, isAddedSnapshot) {
                      if (isAddedSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text('${student.firstName} ${student.lastName}'),
                          trailing: CircularProgressIndicator(),
                        );
                      }

                      bool isAdded = isAddedSnapshot.data ?? false;
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text('${student.firstName} ${student.lastName}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Yaş: ${student.age}'),
                              Text('Branşlar: ${student.branches.join(", ")}'),
                            ],
                          ),
                          trailing: isAdded
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Eklendi',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: Icon(Icons.person_add),
                                  color: Colors.blue,
                                  onPressed: () => _addStudentToCoach(context, student),
                                ),
                        ),
                      );
                    },
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
