import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sportapp/month_page.dart';

class RollCallPage extends StatefulWidget {
  final DateTime? selectedDate;
  final String? coachId;
  const RollCallPage({super.key, this.selectedDate, this.coachId});

  @override
  State<RollCallPage> createState() => _RollCallPageState();
}

class _RollCallPageState extends State<RollCallPage> {
  User? currentUser;
  String todayDate = ""; // Bugünün tarihi
  String monthName = ''; // Ayın adı
  int daysInMonth = 0; // Ayın gün sayısı

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser; // Giriş yapan kullanıcıyı al

    // Yerelleştirmeyi başlat
    initializeDateFormatting('tr_TR', null).then((_) {
      setState(() {
        todayDate = DateFormat('yyyy-MM-dd')
            .format(widget.selectedDate == null ? DateTime.now() : widget.selectedDate!);
        DateTime now = widget.selectedDate == null ? DateTime.now() : widget.selectedDate!;
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
          .doc(widget.coachId ?? currentUser!.uid)
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

  // BottomSheet'i açma fonksiyonu
  void _openMonthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MonthPage(
          monthName: monthName,
          daysInMonth: daysInMonth,
          selectedMonth: DateTime.now().month,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool isTodaySelected = widget.selectedDate == null ||
        (widget.selectedDate!.year == now.year &&
            widget.selectedDate!.month == now.month &&
            widget.selectedDate!.day == now.day);

    return Scaffold(
      appBar: AppBar(
        title: Text('$todayDate'), // Tarih AppBar'ın title'ı olarak gösteriliyor
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today), // Takvim ikonunu göster
            onPressed: () {
              _openMonthBottomSheet(context); // BottomSheet'i aç
            },
          ),
        ],
        leading: isTodaySelected
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // Geri gitme fonksiyonu
                },
              ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Kullanıcı giriş yapmamış'))
          : Column(
              children: [
                // Bugünün tarihi, artık AppBar'da gösteriliyor
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.coachId ?? currentUser!.uid)
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

                            return StreamBuilder<DocumentSnapshot>(
                              // Anlık yoklama durumunu dinle
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.coachId ?? currentUser!.uid)
                                  .collection('rollcall')
                                  .doc(todayDate)
                                  .collection('students')
                                  .doc(studentId)
                                  .snapshots(),
                              builder: (context, rollcallSnapshot) {
                                if (rollcallSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                bool? isPresent;
                                if (rollcallSnapshot.hasData &&
                                    rollcallSnapshot.data!.exists) {
                                  // Eğer veri varsa yoklama durumu alınır
                                  isPresent =
                                      rollcallSnapshot.data!['isPresent'];
                                }

                                Color tileColor;
                                if (isPresent == null) {
                                  tileColor = Colors.grey.shade300; // Henüz işaretlenmedi
                                } else if (isPresent == true) {
                                  tileColor = Colors.green.shade300; // Var
                                } else {
                                  tileColor = Colors.red.shade300; // Yok
                                }

                                return Container(
                                  color: tileColor,
                                  child: ListTile(
                                    title: Text(studentName),
                                    subtitle: Text(
                                        'Yoklama durumu: ${isPresent == null ? "Henüz alınmadı" : (isPresent ? "Var olarak işaretlendi" : "Yok olarak işaretlendi")}'),
                                    trailing: isTodaySelected
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.check,
                                                  color: isPresent == true
                                                      ? Colors.black
                                                      : Colors.white,
                                                ),
                                                onPressed: () {
                                                  // Yoklama: Var
                                                  _markAttendance(
                                                      studentId, true);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: isPresent == false
                                                      ? Colors.black
                                                      : Colors.white,
                                                ),
                                                onPressed: () {
                                                  // Yoklama: Yok
                                                  _markAttendance(
                                                      studentId, false);
                                                },
                                              ),
                                            ],
                                          )
                                        : null, // Geçmiş günlerde yoklama değiştirilmez
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
