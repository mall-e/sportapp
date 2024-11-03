import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RollCallPage extends StatefulWidget {
  final DateTime? selectedDate;
  final String? coachId;
  const RollCallPage({super.key, this.selectedDate, this.coachId});

  @override
  State<RollCallPage> createState() => _RollCallPageState();
}

class _RollCallPageState extends State<RollCallPage> {
  User? currentUser;
  List availableSessions = [];
  String currentDay = '';
  String formattedDate = '';
  bool isLoading = true;
  String? errorMessage;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    //print("Coach ID: ${widget.coachId}");
    _initializeDayAndDate(selectedDate);
    _fetchAvailableSessions();
  }

  void _initializeDayAndDate(DateTime date) {
    formattedDate = DateFormat('yyyy-MM-dd').format(date);

    Map<int, String> dayAbbreviations = {
      1: 'Pzt',
      2: 'Sal',
      3: 'Çrş',
      4: 'Prş',
      5: 'Cum',
      6: 'Cts',
      7: 'Pzr',
    };
    currentDay = dayAbbreviations[date.weekday] ?? '';
  }

  Future<void> _fetchAvailableSessions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (widget.coachId == null) {
        setState(() {
          errorMessage = 'Koç bilgisi bulunamadı';
          isLoading = false;
        });
        return;
      }

      DocumentSnapshot coachSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .get();

      if (!coachSnapshot.exists) {
        setState(() {
          errorMessage = 'Koç bilgisi bulunamadı';
          isLoading = false;
        });
        return;
      }

      final data = coachSnapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        setState(() {
          errorMessage = 'Koç verisi bulunamadı';
          isLoading = false;
        });
        return;
      }

      final sessions = data['sessions'] as List<dynamic>?;
      if (sessions == null) {
        setState(() {
          errorMessage = 'Ders programı henüz oluşturulmamış';
          isLoading = false;
        });
        return;
      }

      List filteredSessions = sessions.where((session) {
        if (session is Map<String, dynamic>) {
          return session['day'] == currentDay &&
              session.containsKey('branch') &&
              session.containsKey('clock');
        }
        return false;
      }).toList();

      setState(() {
        availableSessions = filteredSessions;
        isLoading = false;
        /*if (availableSessions.isEmpty) {
          errorMessage = 'Bu gün için yoklama alınmamıştır';
        }*/
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Veriler yüklenirken bir hata oluştu: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      _initializeDayAndDate(selectedDate);
      _fetchAvailableSessions();
    }
  }


  Future<void> _markAttendance(
      String studentId, String clock, String branch, bool isPresent) async {
    try {
      if (currentUser == null || widget.coachId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bilgisi bulunamadı')),
        );
        return;
      }

      // Seçilen tarihe göre yoklama kaydı
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('rollcall')
          .doc(formattedDate)
          .set({
        'date': formattedDate,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('rollcall')
          .doc(formattedDate)
          .collection(clock)
          .doc('info')
          .set({
        'branch': branch,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId)
          .collection('rollcall')
          .doc(formattedDate)
          .collection(clock)
          .doc(studentId)
          .set({
        'isPresent': isPresent,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Yoklama ${isPresent ? 'var' : 'yok'} olarak kaydedildi'),
          backgroundColor: isPresent ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yoklama kaydedilirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStudentsList(String clock, String branch) {
  bool isToday = formattedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.coachId)
        .collection('students')
        .where('sessions', arrayContainsAny: [
      {'day': currentDay, 'clock': clock, 'branch': branch}
    ]).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Öğrenci bulunamadı.'));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var studentData = snapshot.data!.docs[index];
          String studentId = studentData.id;
          String studentName =
              '${studentData.get('firstName') ?? ''} ${studentData.get('lastName') ?? ''}'
                  .trim();
          if (studentName.isEmpty) studentName = 'İsimsiz Öğrenci';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.coachId)
                .collection('rollcall')
                .doc(formattedDate)
                .collection(clock)
                .doc(studentId)
                .snapshots(),
            builder: (context, rollcallSnapshot) {
              if (rollcallSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const ListTile(
                  title: Text('Yükleniyor...'),
                  trailing: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              bool? isPresent;
              if (rollcallSnapshot.hasData && rollcallSnapshot.data!.exists) {
                isPresent = rollcallSnapshot.data!.get('isPresent') as bool?;
              }

              Color tileColor;
              if (isPresent == null) {
                tileColor = Colors.grey.shade300;
              } else if (isPresent) {
                tileColor = Colors.green.shade300;
              } else {
                tileColor = Colors.red.shade300;
              }

              return Container(
                color: tileColor,
                child: ListTile(
                  title: Text(studentName),
                  subtitle: Text(
                      'Yoklama durumu: ${isPresent == null ? "Henüz alınmadı" : (isPresent ? "Var olarak işaretlendi" : "Yok olarak işaretlendi")}'),
                  trailing: isToday
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
                              onPressed: () => _markAttendance(
                                  studentId, clock, branch, true),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: isPresent == false
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              onPressed: () => _markAttendance(
                                  studentId, clock, branch, false),
                            ),
                          ],
                        )
                      : null, // Yalnızca bugünkü tarih seçiliyken yoklama yapılabilir
                ),
              );
            },
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    bool isToday =
        formattedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
    String title = isToday ? 'Bugünün Yoklaması' : '$formattedDate Yoklaması';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Kullanıcı giriş yapmamış'))
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchAvailableSessions,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    )
                  : availableSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_busy,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Bu gün için ders bulunmamaktadır.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: availableSessions.length,
                                itemBuilder: (context, index) {
                                  var session = availableSessions[index];
                                  String branch =
                                      session['branch'] ?? 'Bilinmeyen Branş';
                                  String clock =
                                      session['clock'] ?? 'Bilinmeyen Saat';

                                  return ExpansionTile(
                                    title: Text('$branch - Saat: $clock'),
                                    children: [
                                      SizedBox(
                                        height: 400,
                                        child:
                                            _buildStudentsList(clock, branch),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
    );
  }
}
