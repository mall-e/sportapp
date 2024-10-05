import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  String id;
  String firstName;
  String lastName;
  int age;
  double height;
  double weight;
  List<String> branches; // Birden fazla branş için liste
  Map<String, String> branchExperiences; // Her branş için deneyim seviyesi
  String healthProblem;
  String role;
  bool? paymentStatus;
  List<Map<String, String>> sessions; // Her branş için session bilgisi

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.height,
    required this.weight,
    required this.branches,
    required this.branchExperiences,
    required this.healthProblem,
    required this.role,
    this.paymentStatus,
    required this.sessions, // Yeni eklenen sessions alanı
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'height': height,
      'weight': weight,
      'branches': branches, // Branş listesi Firestore'a kaydedilecek
      'branchExperiences': branchExperiences, // Branş deneyimleri Firestore'a kaydedilecek
      'healthProblem': healthProblem,
      'role': role,
      'paymentStatus': paymentStatus,
      'sessions': sessions // Sessions listesi de Firestore'a kaydedilecek
          .map((session) => {
                'branch': session['branch'] ?? '',
                'clock': session['clock'] ?? '',
                'day': session['day'] ?? ''
              })
          .toList(),
    };
  }

  factory Student.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      age: data['age'] ?? 0,
      height: (data['height'] as num?)?.toDouble() ?? 0.0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      branches: List<String>.from(data['branches'] ?? []), // Branşları liste olarak çek
      branchExperiences: Map<String, String>.from(data['branchExperiences'] ?? {}), // Branş deneyimlerini map olarak çek
      healthProblem: data['healthProblem'] ?? '',
      role: data['role'] ?? '',
      paymentStatus: data['paymentStatus'] ?? false,
      sessions: List<Map<String, String>>.from(
        (data['sessions'] ?? []).map((session) => {
              'branch': session['branch'] ?? '',
              'clock': session['clock'] ?? '',
              'day': session['day'] ?? ''
            }),
      ), // Sessions listesini Firestore'dan çek
    );
  }
}
