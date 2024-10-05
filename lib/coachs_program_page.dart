import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoachsProgramPage extends StatefulWidget {
  const CoachsProgramPage({super.key});

  @override
  State<CoachsProgramPage> createState() => _CoachsProgramPageState();
}

class _CoachsProgramPageState extends State<CoachsProgramPage> {
  final List<String> days = ['Pzt', 'Sal', 'Çrş', 'Prş', 'Cum', 'Cts', 'Pzr'];
  final List<String> hours = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  Map<String, Map<String, List<Map<String, String>>>> schedule = {};
  Map<String, dynamic>? selectedStudentDetails;
  String? selectedBranch;

  @override
  void initState() {
    super.initState();

    // Tüm hücreler boş olacak şekilde matris oluştur
    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = []; // Boş liste, birden fazla öğrenci olabilir
      }
    }
  }

  // Stream ile Firebase'den veri dinle
  Stream<QuerySnapshot> _getCoachScheduleStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('students')
          .snapshots();
    } else {
      // Eğer kullanıcı yoksa boş bir stream döndürelim
      return const Stream.empty();
    }
  }

  void _updateScheduleFromSnapshot(QuerySnapshot snapshot) {
    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = []; // Tüm gün ve saatler sıfırlanır
      }
    }

    for (var studentDoc in snapshot.docs) {
      List<dynamic> sessions = studentDoc.get('sessions') ?? [];

      for (var session in sessions) {
        String branch = session['branch'] ?? '';
        String day = session['day'] ?? '';
        String hour = session['clock'] ?? '';
        String studentId = studentDoc.id;
        String firstName = studentDoc.get('firstName') ?? '';
        String lastName = studentDoc.get('lastName') ?? '';

        // Seans bilgilerini tabloya ekle
        if (days.contains(day) && hours.contains(hour)) {
          schedule[day]![hour]?.add({
            'studentId': studentId,
            'branch': branch,
            'initials': '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}',
          });
        }
      }
    }

  }

  Future<void> _loadStudentDetails(String studentId, String branch) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('students')
            .doc(studentId)
            .get();

        if (studentSnapshot.exists) {
          setState(() {
            selectedStudentDetails = studentSnapshot.data() as Map<String, dynamic>?;
            selectedBranch = branch; // Seçilen branch bilgisini de kaydet
          });
        }
      }
    } catch (e) {
      print('Öğrenci bilgileri yüklenirken hata oluştu: $e');
    }
  }

  void _onCellTap(String day, String hour) {
    final selectedSessions = schedule[day]?[hour] ?? [];
    if (selectedSessions.isNotEmpty) {
      // İlk öğrenci ID'sini ve branch bilgisini seç ve bilgilerini yükle
      _loadStudentDetails(
          selectedSessions.first['studentId']!, selectedSessions.first['branch']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach\'s Program'),
      ),
      body: Column(
        children: [
          // Takvim yapısı: ekranın yarısını kaplayacak ve padding ekleyecek
          StreamBuilder<QuerySnapshot>(
            stream: _getCoachScheduleStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Veritabanı hatası oluştu.'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                // Programı güncelle
                _updateScheduleFromSnapshot(snapshot.data!);

                return Container(
                  height: screenHeight * 0.5, // Ekranın yarısını kaplar
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Kenarlardan padding
                  child: Column(
                    children: [
                      // Günlerin başlıkları
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 50), // Boşluk, saatler için yer
                          ...days.map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8.0), // Günlerden sonra boşluk
                      Expanded(
                        child: ListView.builder(
                          itemCount: hours.length,
                          itemBuilder: (context, index) {
                            String hour = hours[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Saatlerin gösterimi
                                  SizedBox(
                                    width: 50,
                                    child: Center(
                                      child: Text(
                                        hour,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  ...days.map((day) {
                                    return Expanded(
                                      child: InkWell(
                                        onTap: () => _onCellTap(day, hour),
                                        borderRadius: BorderRadius.circular(50),
                                        splashColor: Colors.blue.withOpacity(0.3),
                                        child: Container(
                                          margin: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: schedule[day]![hour]?.isNotEmpty == true
                                                ? Colors.green.withOpacity(0.8)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                          width: screenWidth * 0.1, // Yuvarlak hücre genişliği
                                          height: screenWidth * 0.1, // Yuvarlak hücre yüksekliği
                                          child: Center(
                                            child: Text(
                                              schedule[day]![hour]?.isNotEmpty == true
                                                  ? schedule[day]![hour]!.first['initials'] ?? ''
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: Text('Program bulunamadı.'));
              }
            },
          ),
          // Seçilen öğrencinin bilgilerini gösteren Card
          if (selectedStudentDetails != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: ThemeData().primaryColor,
                              backgroundImage: selectedStudentDetails!['profilePicUrl'] != null
                                  ? NetworkImage(selectedStudentDetails!['profilePicUrl'])
                                  : null,
                              child: selectedStudentDetails!['profilePicUrl'] == null
                                  ? Text(
                                      (selectedStudentDetails!['firstName'][0] +
                                          selectedStudentDetails!['lastName'][0])
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${selectedStudentDetails!['firstName']} ${selectedStudentDetails!['lastName']}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Burada seansa özel branch bilgisi gösteriliyor
                                Text(
                                  'Branş: $selectedBranch',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kilo: ${selectedStudentDetails!['weight'] ?? 'Bilinmiyor'} kg',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Boy: ${selectedStudentDetails!['height'] ?? 'Bilinmiyor'} cm',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
