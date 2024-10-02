import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sportapp/month_page.dart';

class RollCallPage extends StatefulWidget {
  const RollCallPage({super.key, required DateTime selectedDate});

  @override
  State<RollCallPage> createState() => _RollCallPageState();
}

class _RollCallPageState extends State<RollCallPage> {
  User? currentUser;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Bugünün tarihi
  String monthName = ''; // Ayın adı
  int daysInMonth = 0; // Ayın gün sayısı

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser; // Giriş yapan kullanıcıyı al

    // Yerelleştirmeyi başlat
    initializeDateFormatting('tr_TR', null).then((_) {
      setState(() {
        DateTime now = DateTime.now();
        monthName = DateFormat('MMMM', 'tr_TR').format(now); // Ayın adı
        daysInMonth = DateTime(now.year, now.month + 1, 0).day; // Bulunduğunuz ayın gün sayısını hesapla
      });
    });
  }

  // Öğrencinin yoklama durumunu kaydetme fonksiyonu
  Future<void> _markAttendance(String studentId, bool isPresent) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('rollcall')
          .doc(todayDate) // Bugünün tarihine göre belge
          .collection('students')
          .doc(studentId)
          .set({
        'isPresent': isPresent,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            // Ayın adı ve gün sayısını gönderiyoruz
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MonthPage(
                  monthName: monthName,
                  daysInMonth: daysInMonth,
                ),
              ),
            );
          },
          child: Text(monthName), // Ayın adı burada gösteriliyor
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Kullanıcı giriş yapmamış'))
          : Column(
              children: [
                // Bugünün tarihi
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Tarih: $todayDate',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid)
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('Bir hata oluştu.'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var studentData = snapshot.data!.docs[index];
                            String studentId = studentData.id;
                            String studentName =
                                '${studentData['firstName']} ${studentData['lastName']}';

                            return FutureBuilder<DocumentSnapshot>(
                              // Bugünkü yoklama durumunu kontrol et
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser!.uid)
                                  .collection('rollcall')
                                  .doc(todayDate)
                                  .collection('students')
                                  .doc(studentId)
                                  .get(),
                              builder: (context, rollcallSnapshot) {
                                bool? isPresent;
                                if (rollcallSnapshot.hasData && rollcallSnapshot.data!.exists) {
                                  // Eğer veri varsa yoklama durumu alınır
                                  isPresent = rollcallSnapshot.data!['isPresent'];
                                }

                                return ListTile(
                                  title: Text(studentName),
                                  subtitle: Text(
                                      'Yoklama durumu: ${isPresent == null ? "Henüz alınmadı" : (isPresent ? "Var" : "Yok")}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.check,
                                          color: isPresent == true ? Colors.green : Colors.grey,
                                        ),
                                        onPressed: () {
                                          // Yoklama: Var
                                          _markAttendance(studentId, true);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: isPresent == false ? Colors.red : Colors.grey,
                                        ),
                                        onPressed: () {
                                          // Yoklama: Yok
                                          _markAttendance(studentId, false);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('Öğrenci bulunamadı.'));
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
