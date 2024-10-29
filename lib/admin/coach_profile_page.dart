import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/models/coach_model.dart';

class CoachProfilePage extends StatelessWidget {
  final String coachId;

  const CoachProfilePage({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koç Profili'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(coachId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Koç bilgisi bulunamadı.'));
          }

          // Coach modelini Firestore'dan gelen veriyle oluşturuyoruz
          Coach coach = Coach.fromFirestore(snapshot.data!);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coach.profilePictureUrl != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(coach.profilePictureUrl!),
                  ),
                const SizedBox(height: 16),
                Text(
                  'İsim: ${coach.firstName} ${coach.lastName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${coach.email}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Branşlar:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Branşlar listeleniyor
                if (coach.branches != null && coach.branches.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: coach.branches.map((branch) => Text('- $branch')).toList(),
                  )
                else
                  const Text('Branş bilgisi yok.'),
              ],
            ),
          );
        },
      ),
    );
  }
}
