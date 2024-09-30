import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  String id;  // Firestore belgesi için ID
  String firstName;
  String lastName;
  int age;
  double height;
  double weight;
  String branch;
  bool paymentStatus;  // Ödeme durumu

  Student({
    required this.id,  // ID de constructor'a eklendi
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.height,
    required this.weight,
    required this.branch,
    required this.paymentStatus,
  });

  // Firestore için map yapısı
  Map<String, dynamic> toMap() {
    return {
      'id': id,  // ID de Firestore'a kaydedilecek
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'height': height,
      'weight': weight,
      'branch': branch,
      'paymentStatus': paymentStatus,  // Ödeme durumu Firestore'a kaydedilecek
    };
  }

  // Firestore'dan veriyi almak için bir factory method
  factory Student.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,  // Firestore belgesi ID'si
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      age: data['age'] ?? 0,
      height: (data['height'] as num?)?.toDouble() ?? 0.0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      branch: data['branch'] ?? '',
      paymentStatus: data['paymentStatus'] ?? false,
    );
  }
}
