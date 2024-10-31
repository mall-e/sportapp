import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSessionControlPage extends StatefulWidget {
  final String? coachId;

  const AdminSessionControlPage({super.key, this.coachId});

  @override
  State<AdminSessionControlPage> createState() => _AdminSessionControlPageState();
}

class _AdminSessionControlPageState extends State<AdminSessionControlPage> {
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
  List<String> coachBranches = []; // Hoca'nın branşları
  String? selectedBranch;

  @override
  void initState() {
    super.initState();

    // Tüm hücreler boş olacak şekilde matris oluştur
    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = []; // Boş liste, birden fazla oturum olabilir
      }
    }
  }

  // Firestore'dan hocanın programını dinle
  Stream<DocumentSnapshot> _getCoachScheduleStream() {
    if (widget.coachId != null) {
      return FirebaseFirestore.instance.collection('users').doc(widget.coachId).snapshots();
    } else {
      // Eğer coachId yoksa boş bir stream döndürelim
      return const Stream.empty();
    }
  }

  void _updateScheduleFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      // Hocanın branşlarını alıyoruz
      if (data.containsKey('branches')) {
        coachBranches = List<String>.from(data['branches']);
      }

      // Programı güncellerken önce sıfırlıyoruz
      for (var day in days) {
        schedule[day] = {};
        for (var hour in hours) {
          schedule[day]![hour] = []; // Boş liste ile sıfırlıyoruz
        }
      }

      // Eğer 'sessions' varsa onları tabloya ekleyelim
      if (data.containsKey('sessions')) {
        List<dynamic> sessions = data['sessions'] ?? [];

        for (var session in sessions) {
          String branch = session['branch'] ?? '';
          String day = session['day'] ?? '';
          String hour = session['clock'] ?? '';

          // Seans bilgilerini tabloya ekle
          if (days.contains(day) && hours.contains(hour)) {
            schedule[day]![hour]?.add({
              'branch': branch,
            });
          }
        }
      }
    }
  }

  // Seçim ekranı: Hoca'nın branşlarını seçme ve saati kaydetme
  // Seçim ekranı: Hoca'nın branşlarını seçme ve saati kaydetme veya kaldırma
void _onCellTap(String day, String hour) async {
  if (schedule[day]![hour]!.isNotEmpty) {
    // Zaten oturum varsa, mevcut branşları listeler ve kaldırmak istediğini sorar
    String? selectedBranchToRemove = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Oturumu Kaldır'),
          children: schedule[day]![hour]!.map((session) {
            String branch = session['branch'] ?? '';
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, branch);
              },
              child: Text('$branch oturumunu kaldır'),
            );
          }).toList(),
        );
      },
    );

    if (selectedBranchToRemove != null) {
      // Seçilen branşı kaldır
      setState(() {
        schedule[day]![hour] = schedule[day]![hour]!
            .where((session) => session['branch'] != selectedBranchToRemove)
            .toList();
      });

      // Firestore'dan oturumu kaldırıyoruz
      _removeSessionFromFirestore(day, hour, selectedBranchToRemove);
      return;
    }
  } else if (coachBranches.isNotEmpty) {
    // Oturum yoksa, branş seçtirme ekranını göster
    String? selectedBranch = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Branş Seç'),
          children: coachBranches.map((branch) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, branch); // Seçilen branşı döndür
              },
              child: Text(branch),
            );
          }).toList(),
        );
      },
    );

    if (selectedBranch != null) {
      // Seçilen branşı kaydet ve ekrana ekle
      setState(() {
        schedule[day]![hour]?.add({
          'branch': selectedBranch,
        });
      });

      // Firestore'da 'sessions' verisine ekle
      _saveSessionToFirestore(day, hour, selectedBranch);
    }
  }
}

// Firestore'da 'sessions' verisinden belirtilen branşı kaldırma
Future<void> _removeSessionFromFirestore(String day, String hour, String branch) async {
  if (widget.coachId != null) {
    final coachRef = FirebaseFirestore.instance.collection('users').doc(widget.coachId);

    await coachRef.update({
      'sessions': FieldValue.arrayRemove([
        {
          'day': day,
          'clock': hour,
          'branch': branch,
        }
      ])
    });
  }
}


  // Firestore'da 'sessions' verisine kaydetme
  Future<void> _saveSessionToFirestore(String day, String hour, String branch) async {
    if (widget.coachId != null) {
      final coachRef = FirebaseFirestore.instance.collection('users').doc(widget.coachId);

      await coachRef.update({
        'sessions': FieldValue.arrayUnion([
          {
            'day': day,
            'clock': hour,
            'branch': branch,
          }
        ])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koç Programı'),
      ),
      body: Column(
        children: [
          // Takvim yapısı: ekranın yarısını kaplayacak ve padding ekleyecek
          StreamBuilder<DocumentSnapshot>(
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
                                                  ? schedule[day]![hour]!.first['branch'] ?? ''
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
        ],
      ),
    );
  }
}
