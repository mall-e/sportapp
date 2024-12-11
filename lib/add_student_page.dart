import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sportapp/models/student_model.dart';
import 'package:sportapp/widgets/colors.dart';

class AddStudentPage extends StatefulWidget {
  final String? coachId;
  final bool showBackButton;
  const AddStudentPage({super.key, this.coachId,this.showBackButton = false,});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  File? _imageFile;
  List<Map<String, String>> _branchExperiencePairs = [];
  List<Map<String, String>> _sessions = [];

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
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton ? IconButton( // Koşula bağlı leading
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        title: const Text(
          'Öğrenci Ekle',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add, color: AppColors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExistingStudentsPage(
                    coachId: widget.coachId ?? '',
                  ),
                ),
              );
            },
            tooltip: "Var Olan Öğrencileri Görüntüle",
          ),
        ],
      ),
      body: AddStudentInformation(
        onBranchExperienceAdded: (branch, experience) {
          setState(() {
            _branchExperiencePairs
                .add({'branch': branch, 'experience': experience});
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
      ),
    );
  }
}

class AddStudentInformation extends StatefulWidget {
  final Function(String, String) onBranchExperienceAdded;
  final List<Map<String, String>> branchExperiencePairs;
  final List<Map<String, String>> sessions;
  final String? coachId;

  const AddStudentInformation({
    super.key,
    required this.onBranchExperienceAdded,
    required this.branchExperiencePairs,
    required this.sessions,
    this.coachId,
  });

  @override
  State<AddStudentInformation> createState() => _AddStudentInformationState();
}

class _AddStudentInformationState extends State<AddStudentInformation> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _branchController = TextEditingController();
  final _healthproblemController = TextEditingController();
  bool _paymentStatus = false;

  String _selectedExperience = 'Deneyimsiz';
  final List<String> experienceLevels = [
    'Deneyimsiz',
    '1-3 yıl',
    '3-5 yıl',
    '5+ yıl'
  ];

  InputDecoration _buildInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.blue) : null,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.blue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void addStudent() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapılmadı!')),
      );
      return;
    }

    String coachId = widget.coachId ?? currentUser.uid;

    Student student = Student(
      id: '',
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      age: int.tryParse(_ageController.text) ?? 0,
      height: double.tryParse(_heightController.text) ?? 0.0,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      branches:
          widget.branchExperiencePairs.map((pair) => pair['branch']!).toList(),
      branchExperiences: Map.fromIterable(widget.branchExperiencePairs,
          key: (pair) => pair['branch']!, value: (pair) => pair['experience']!),
      healthProblem: _healthproblemController.text,
      role: 'student',
      paymentStatus: _paymentStatus,
      sessions: widget.sessions,
      coachId: coachId,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(coachId)
          .collection('students')
          .add(student.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Öğrenci başarıyla eklendi!'),
          backgroundColor: AppColors.blue,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğrenci eklenirken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.lightBlue,
                  child: const Icon(
                    Icons.person_add,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            decoration: _buildInputDecoration('Ad', Icons.person),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: _buildInputDecoration('Soyad', Icons.person_outline),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration:
                      _buildInputDecoration('Yaş', Icons.calendar_today),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('Boy (cm)', Icons.height),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration:
                _buildInputDecoration('Kilo (kg)', Icons.fitness_center),
          ),
          const SizedBox(height: 24),
          Text(
            'Branşlar ve Deneyim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _branchController,
                  decoration: _buildInputDecoration('Branş', Icons.sports),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedExperience,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedExperience = newValue!;
                        });
                      },
                      items: experienceLevels
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style:
                                TextStyle(fontSize: 14, color: AppColors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (_branchController.text.isNotEmpty) {
                    widget.onBranchExperienceAdded(
                      _branchController.text,
                      _selectedExperience,
                    );
                    _branchController.clear();
                    setState(() {
                      _selectedExperience = 'Deneyimsiz';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.branchExperiencePairs.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.branchExperiencePairs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pair = widget.branchExperiencePairs[index];
                  return ListTile(
                    title: Text(
                      pair['branch']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Deneyim: ${pair['experience']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          widget.branchExperiencePairs.removeAt(index);
                          widget.sessions.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _healthproblemController,
            decoration:
                _buildInputDecoration('Sağlık Sorunu', Icons.medical_services),
            maxLines: 1,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Öğrenciyi Ekle',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
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
    _branchController.dispose();
    _healthproblemController.dispose();
    super.dispose();
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _getCoachBranches() async {
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
    
    QuerySnapshot coachesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .get();

    for (var coach in coachesSnapshot.docs) {
      if (coach.id == widget.coachId) continue;

      QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(coach.id)
          .collection('students')
          .get();

      for (var studentDoc in studentsSnapshot.docs) {
        Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;
        Student student = Student.fromMap(data);
        student.id = studentDoc.id;
        student.originalCoachId = coach.id;
        
        List<String> studentBranches = List<String>.from(data['branches'] ?? []);
        
        // Search query filter
        String fullName = '${student.firstName} ${student.lastName}'.toLowerCase();
        if (_searchQuery.isNotEmpty && !fullName.contains(_searchQuery.toLowerCase())) {
          continue;
        }

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
        .where('originalId', isEqualTo: studentId)
        .get();

    return existingStudent.docs.isNotEmpty;
  }

  Future<void> _addStudentToCoach(BuildContext context, Student student) async {
    try {
      if (await _isStudentAlreadyAdded(student.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu öğrenci zaten eklenmiş.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Map<String, dynamic> studentData = student.toMap();
      studentData['originalId'] = student.id;
      studentData['originalCoachId'] = student.originalCoachId;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('students')
          .add(studentData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öğrenci başarıyla eklendi!'),
          backgroundColor: AppColors.blue,
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öğrenci eklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Diğer Koçların Öğrencileri',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Öğrenci Ara...',
                prefixIcon: Icon(Icons.search, color: AppColors.blue),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.blue),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _getCoachBranches(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.blue));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Hata: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<List<Student>>(
                  future: _getFilteredStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Hata: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }

                    final students = snapshot.data ?? [];

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: AppColors.blue.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Uygun branşlarda öğrenci bulunamadı.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];

                        return FutureBuilder<bool>(
                          future: _isStudentAlreadyAdded(student.id),
                          builder: (context, isAddedSnapshot) {
                            if (isAddedSnapshot.connectionState == ConnectionState.waiting) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  title: Text('${student.firstName} ${student.lastName}'),
                                  trailing: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.blue,
                                    ),
                                  ),
                                ),
                              );
                            }

                            bool isAdded = isAddedSnapshot.data ?? false;
                            
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.lightBlue,
                                  child: Text(
                                    '${student.firstName[0]}${student.lastName[0]}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${student.firstName} ${student.lastName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Text(
                                      'Yaş: ${student.age}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: student.branches.map((branch) {
                                        return Chip(
                                          label: Text(
                                            branch,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: AppColors.blue,
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                trailing: isAdded
                                    ? Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.grey[600],
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Eklendi',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: () => _addStudentToCoach(context, student),
                                        icon: Icon(Icons.person_add, size: 16),
                                        label: Text('Ekle'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}