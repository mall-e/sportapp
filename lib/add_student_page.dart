import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sportapp/models/student_model.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  File? _imageFile;
  bool _paymentStatus = false;  // Ödeme durumu kontrolü

  Future<void> _pickImage() async {
    // İzin kontrolü ve isteme
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    // Eğer izin verilmişse kamerayı aç
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
      // Kullanıcı izin vermezse, uyarı mesajı göster
      print('Kamera izni verilmedi');
    }
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      // Firebase Storage referansı
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('students/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Fotoğrafı Firebase Storage'a yükleme
      await storageRef.putFile(imageFile);
      print('Image uploaded to Firebase Storage');
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          )),
          Expanded(flex: 2, child: AddStudentInformation(paymentStatus: _paymentStatus)),
        ],
      ),
    ));
  }
}

class AddStudentInformation extends StatefulWidget {
  final bool paymentStatus;
  const AddStudentInformation({super.key, required this.paymentStatus});

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
  bool _paymentStatus = false;  // Ödeme durumu başlangıçta false

  void addStudent(Student student) async {
  try {
    // Firebase Authentication'dan şu anki kullanıcıyı al
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Kullanıcının 'uid'si ile kişiye özel 'students' koleksiyonuna öğrenci ekleme
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)  // Kullanıcının uid'sine göre belge seçiliyor
          .collection('students')  // Bu kullanıcının students alt koleksiyonuna ekleniyor
          .add(student.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci başarıyla eklendi!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapılmadı!')),
      );
    }
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
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Ad',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Soyad',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Yaş',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Boy',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Kilo',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _branchController,
              decoration: InputDecoration(
                labelText: 'Branş',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _healthproblemController,
              decoration: InputDecoration(
                labelText: 'Sağlık sorunu',
              ),
            ),
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                // TextField'dan alınan bilgileri model oluşturmak
                Student student = Student(
                  id: "",
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  age: int.tryParse(_ageController.text) ?? 0,
                  height: double.tryParse(_heightController.text) ?? 0.0,
                  weight: double.tryParse(_weightController.text) ?? 0.0,
                  branch: _branchController.text,
                  healthProblem: _healthproblemController.text,
                  paymentStatus: _paymentStatus,  // Ödeme durumu eklendi
                  role: 'student',  // role olarak "student" ekleniyor
                );

                // Firestore'a kaydetme
                addStudent(student);

              },
              child: Text('Öğrenciyi Ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
