import 'package:cloud_firestore/cloud_firestore.dart';
class Student {
  String id;
  String? originalCoachId; // Öğrencinin orijinal koçunun ID'si
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
  String coachId; // Koç ID'si

  Student({
    required this.id,
    this.originalCoachId,
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
    required this.sessions,
    required this.coachId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalCoachId': originalCoachId,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'height': height,
      'weight': weight,
      'branches': branches,
      'branchExperiences': branchExperiences,
      'healthProblem': healthProblem,
      'role': role,
      'paymentStatus': paymentStatus,
      'sessions': sessions.map((session) => {
            'branch': session['branch'] ?? '',
            'clock': session['clock'] ?? '',
            'day': session['day'] ?? ''
          }).toList(),
      'coachId': coachId,
    };
  }

  // fromMap metodu, Map<String, dynamic> verisini alır ve bir Student nesnesi döndürür
  factory Student.fromMap(Map<String, dynamic> data) {
  return Student(
    id: data['id'] ?? '',
    originalCoachId: data['originalCoachId'],
    firstName: data['firstName'] ?? '',
    lastName: data['lastName'] ?? '',
    age: data['age'] ?? 0,
    height: (data['height'] as num?)?.toDouble() ?? 0.0,
    weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
    branches: List<String>.from(data['branches'] ?? []),
    
    // branchExperiences'ı Map<String, String> türüne dönüştürme
    branchExperiences: Map<String, String>.from(
      (data['branchExperiences'] ?? {}).map((key, value) {
        return MapEntry(key.toString(), value.toString());
      }),
    ),

    healthProblem: data['healthProblem'] ?? '',
    role: data['role'] ?? '',
    paymentStatus: data['paymentStatus'] ?? false,
    
    // sessions listesini List<Map<String, String>> türüne dönüştürme
    sessions: (data['sessions'] as List<dynamic>?)?.map((session) {
      return {
        'branch': session['branch']?.toString() ?? '',
        'clock': session['clock']?.toString() ?? '',
        'day': session['day']?.toString() ?? ''
      };
    }).toList() ?? [],

    coachId: data['coachId'] ?? '',
  );
}

}
