import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/models/student_model.dart';

class StudentInfoPage extends StatefulWidget {
  final Student student;

  const StudentInfoPage({super.key, required this.student});

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  // TextEditingController'lar
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _branchController;

  bool _paymentStatus = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.student.firstName);
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _ageController = TextEditingController(text: widget.student.age.toString());
    _heightController = TextEditingController(text: widget.student.height.toString());
    _weightController = TextEditingController(text: widget.student.weight.toString());
    _branchController = TextEditingController(text: widget.student.branch);
    _paymentStatus = widget.student.paymentStatus;
  }

  // Firestore güncelleme fonksiyonu
  Future<void> _updateStudent() async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.student.id)  // Belge id'sini ilk isme göre alabilirsiniz; bu projenize göre değişebilir
          .update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'age': int.tryParse(_ageController.text) ?? widget.student.age,
        'height': double.tryParse(_heightController.text) ?? widget.student.height,
        'weight': double.tryParse(_weightController.text) ?? widget.student.weight,
        'branch': _branchController.text,
        'paymentStatus': _paymentStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğrenci bilgileri başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme başarısız: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğrenci Bilgileri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture and name
            Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),

            // First Name
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Ad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Last Name
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Age
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yaş',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Height
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Boy (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Weight
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilo (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Branch
            TextField(
              controller: _branchController,
              decoration: InputDecoration(
                labelText: 'Branş',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Payment Status Switch
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

            // Update Button
            Center(
              child: ElevatedButton(
                onPressed: _updateStudent,
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
    _branchController.dispose();
    super.dispose();
  }
}
