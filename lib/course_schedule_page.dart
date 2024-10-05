import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseSchedulePage extends StatefulWidget {
  final String studentName;
  final List<String> availableBranches;
  final String studentId; // Öğrencinin ID'si

  const CourseSchedulePage({
    super.key,
    required this.studentName,
    required this.availableBranches,
    required this.studentId,
  });

  @override
  State<CourseSchedulePage> createState() => _CourseSchedulePageState();
}

class _CourseSchedulePageState extends State<CourseSchedulePage> {
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

  Map<String, Map<String, String?>> schedule = {};

  @override
  void initState() {
    super.initState();

    // Tüm hücreler boş olacak şekilde matris oluştur
    for (var day in days) {
      schedule[day] = {};
      for (var hour in hours) {
        schedule[day]![hour] = null;
      }
    }
  }

  // Firestore'daki verileri stream olarak dinleyen yapı
  Stream<DocumentSnapshot> _scheduleStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('students')
          .doc(widget.studentId)
          .snapshots();
    }
    throw Exception('Kullanıcı doğrulanamadı.');
  }

  void _selectSession(String day, String hour) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedBranch;
        return AlertDialog(
          title: Text('$day, Saat: $hour'),
          content: DropdownButton<String>(
            hint: const Text('Branş Seçin'),
            value: selectedBranch,
            items: widget.availableBranches.map((branch) {
              return DropdownMenuItem<String>(
                value: branch,
                child: Text(branch),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedBranch = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (selectedBranch != null) {
                  setState(() {
                    schedule[day]![hour] = selectedBranch;
                    _saveSessionToFirestore(day, hour, selectedBranch!);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSessionToFirestore(
      String day, String hour, String branch) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentReference studentDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('students')
            .doc(widget.studentId);

        DocumentSnapshot studentSnapshot = await studentDocRef.get();

        if (studentSnapshot.exists) {
          List<dynamic> sessions = studentSnapshot.get('sessions') ?? [];

          // Mevcut oturumları kontrol et
          bool sessionUpdated = false;

          for (var session in sessions) {
            if (session['branch'] == branch) {
              // Aynı branch bulundu, sadece güncellenmeli
              session['clock'] = hour;
              session['day'] = day;
              sessionUpdated = true;
              break;
            }
          }

          if (!sessionUpdated) {
            // Aynı branch yoksa yeni bir session ekle
            sessions.add({
              'branch': branch,
              'clock': hour,
              'day': day,
            });
          }

          // Firestore'daki sessions dizisini güncelle
          await studentDocRef.update({'sessions': sessions});

          print('Oturum başarıyla kaydedildi: $day, $hour, $branch');
        }
      }
    } catch (e) {
      print('Veritabanına kaydedilirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} için Ders Programı'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _scheduleStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Veritabanından gelen veriyi tabloya işleme
          if (snapshot.hasData && snapshot.data!.exists) {
            List<dynamic> sessions = snapshot.data!.get('sessions') ?? [];

            // Veriyi tabloya işlemek için önce sıfırlıyoruz
            for (var day in days) {
              for (var hour in hours) {
                schedule[day]![hour] = null;
              }
            }

            // Gelen veriyi tabloya uygun şekilde ayarlıyoruz
            for (var session in sessions) {
              String branch = session['branch'] ?? '';
              String day = session['day'] ?? '';
              String hour = session['clock'] ?? '';

              if (day.isNotEmpty && hour.isNotEmpty) {
                // Veritabanındaki verileri tabloya yerleştir
                schedule[day]?[hour] = branch;
              }
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(color: Colors.blue),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                  },
                  children: [
                    // İlk satır (Günler)
                    TableRow(
                      children: [
                        const SizedBox.shrink(), // Boş hücre
                        ...days.map((day) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      ],
                    ),
                    // Saatler ve hücreler matrisi
                    ...hours.map((hour) {
                      return TableRow(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(hour),
                            ),
                          ),
                          ...days.map((day) {
                            return GestureDetector(
                              onTap: () => _selectSession(day, hour),
                              child: Container(
                                height: 60,
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: schedule[day]![hour] != null
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.white,
                                ),
                                child: Center(
                                  child: Text(schedule[day]![hour] ?? '-'),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
