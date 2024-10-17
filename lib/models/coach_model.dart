import 'package:cloud_firestore/cloud_firestore.dart';

class Coach {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePictureUrl; // Koçun profil resmi (isteğe bağlı)

  Coach({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePictureUrl,
  });

  // Firestore'dan veri çekerken kullanılan factory method
  factory Coach.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coach(
      id: doc.id, // Firestore'daki belge id'si
      firstName: data['firstName'] ?? '', // Eğer veri yoksa varsayılan olarak boş string
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePictureUrl'], // Eğer profil resmi varsa kullanır
    );
  }

  // Coach nesnesini Map'e çevirme (Veri eklerken ya da güncellerken kullanılabilir)
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
