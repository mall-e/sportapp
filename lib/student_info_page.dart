import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/course_schedule_page.dart';
import 'package:sportapp/models/student_model.dart';
import 'package:sportapp/widgets/colors.dart';

class StudentInfoPage extends StatefulWidget {
  final Student student;
  final String? coachId;

  const StudentInfoPage({super.key, required this.student, this.coachId});

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
  final List<String> _experienceLevels = ['Deneyimsiz', '1-3 yıl', '3-5 yıl', '5+ yıl'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.student.firstName);
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _ageController = TextEditingController(text: widget.student.age.toString());
    _heightController = TextEditingController(text: widget.student.height.toString());
    _weightController = TextEditingController(text: widget.student.weight.toString());
    _healthproblemController = TextEditingController(text: widget.student.healthProblem);
    _paymentStatus = widget.student.paymentStatus ?? false;
    _branches = List.from(widget.student.branches);
    _branchExperiences = Map.from(widget.student.branchExperiences);
  }

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
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _updateStudent() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentReference studentDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.coachId ?? currentUser.uid)
            .collection('students')
            .doc(widget.student.id);

        await studentDocRef.update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'age': int.tryParse(_ageController.text) ?? widget.student.age,
          'height': double.tryParse(_heightController.text) ?? widget.student.height,
          'weight': double.tryParse(_weightController.text) ?? widget.student.weight,
          'branches': _branches,
          'branchExperiences': _branchExperiences,
          'healthProblem': _healthproblemController.text,
          'paymentStatus': _paymentStatus,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öğrenci bilgileri güncellendi'),
            backgroundColor: AppColors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız: $e')),
      );
    }
  }

  void _editBranch(String branch, String experience) {
    TextEditingController branchController = TextEditingController(text: branch);
    String selectedExperience = experience;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('Branş Düzenle',
                  style: TextStyle(color: AppColors.blue)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: branchController,
                    decoration: _buildInputDecoration('Branş', Icons.sports),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<String>(
                      value: selectedExperience,
                      isExpanded: true,
                      underline: Container(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedExperience = newValue!;
                        });
                      },
                      items: _experienceLevels.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('İptal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    int index = _branches.indexOf(branch);
                    _branches[index] = branchController.text;
                    _branchExperiences[branchController.text] = selectedExperience;
                    if (branch != branchController.text) {
                      _branchExperiences.remove(branch);
                    }
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Öğrenci Bilgileri',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.schedule, color: AppColors.blue),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseSchedulePage(
                  studentName: '${widget.student.firstName} ${widget.student.lastName}',
                  availableBranches: _branches,
                  studentId: widget.student.id,
                  coachId: widget.coachId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.lightBlue,
                  child: Text(
                    '${widget.student.firstName[0]}${widget.student.lastName[0]}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _firstNameController,
                decoration: _buildInputDecoration('Ad', Icons.person),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: _buildInputDecoration('Soyad', Icons.person_outline),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('Yaş', Icons.calendar_today),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('Boy (cm)', Icons.height),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Kilo (kg)', Icons.fitness_center),
              ),
              SizedBox(height: 24),
              Text(
                'Branşlar ve Deneyim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _branches.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    String branch = _branches[index];
                    String experience = _branchExperiences[branch] ?? 'Deneyimsiz';
                    return ListTile(
                      title: Text(branch,
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Deneyim: $experience'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: AppColors.blue),
                        onPressed: () => _editBranch(branch, experience),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _healthproblemController,
                decoration: _buildInputDecoration('Sağlık Sorunu', Icons.medical_services),
                maxLines: 1,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Bilgileri Güncelle',
                    style: TextStyle(fontSize: 16, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
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