import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:intl/date_symbol_data_local.dart';

class RollCallPage extends StatefulWidget {
  final DateTime? selectedDate;
  final String? coachId;
  final bool showBackButton;
  const RollCallPage({
    super.key,
    this.selectedDate,
    this.coachId,
    this.showBackButton = false,
  });

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
    initializeDateFormatting('tr_TR', null).then((_) {
      currentUser = FirebaseAuth.instance.currentUser;
      _initializeDayAndDate(selectedDate);
      _fetchAvailableSessions();
    });
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
    bool isToday =
        formattedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());

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
          return Center(
            child: Text(
              'Bir hata oluştu: ${snapshot.error}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Öğrenci bulunamadı.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var studentData = snapshot.data!.docs[index];
            String studentId = studentData.id;
            String firstName = studentData.get('firstName') ?? '';
            String lastName = studentData.get('lastName') ?? '';
            String studentName = '$firstName $lastName'.trim();
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
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                bool? isPresent;
                if (rollcallSnapshot.hasData && rollcallSnapshot.data!.exists) {
                  isPresent = rollcallSnapshot.data!.get('isPresent') as bool?;
                }

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 4,
                            color: isPresent == null
                                ? Colors.grey[300]!
                                : isPresent
                                    ? AppColors.green
                                    : AppColors.red,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lightBlue,
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          isPresent == null
                              ? 'Yoklama alınmadı'
                              : isPresent
                                  ? 'Var olarak işaretlendi'
                                  : 'Yok olarak işaretlendi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: isToday
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAttendanceButton(
                                    isSelected: isPresent == true,
                                    icon: Icons.check_circle_outline,
                                    color: AppColors.green,
                                    onTap: () => _markAttendance(
                                        studentId, clock, branch, true),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAttendanceButton(
                                    isSelected: isPresent == false,
                                    icon: Icons.cancel_outlined,
                                    color: AppColors.red,
                                    onTap: () => _markAttendance(
                                        studentId, clock, branch, false),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceButton({
    required bool isSelected,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: isSelected ? color : Colors.grey[400],
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isToday =
        formattedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
    String formattedDisplayDate =
        DateFormat('d MMMM yyyy', 'tr_TR').format(selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                // Koşula bağlı leading
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yoklama',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              formattedDisplayDate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.blue),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: currentUser == null
          ? Center(
              child: Text(
                'Kullanıcı giriş yapmamış',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                )
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchAvailableSessions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                              Icon(Icons.event_busy,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Bu gün için ders bulunmamaktadır.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: availableSessions.length,
                          itemBuilder: (context, index) {
                            var session = availableSessions[index];
                            String branch =
                                session['branch'] ?? 'Bilinmeyen Branş';
                            String clock =
                                session['clock'] ?? 'Bilinmeyen Saat';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.sports,
                                      color: AppColors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    branch,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    clock,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  children: [
                                    SizedBox(
                                      height: 400,
                                      child: _buildStudentsList(clock, branch),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
    );
  }
}
