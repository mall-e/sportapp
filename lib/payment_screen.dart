import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportapp/widgets/colors.dart';

class MonthlyPaymentScreen extends StatefulWidget {
  final String? coachId;

  const MonthlyPaymentScreen({super.key, this.coachId});

  @override
  State<MonthlyPaymentScreen> createState() => _MonthlyPaymentScreenState();
}

class _MonthlyPaymentScreenState extends State<MonthlyPaymentScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _updateMonthlyPaymentStatus(
      String studentId, String month, bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.coachId ?? currentUser!.uid)
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .doc(month)
          .set({'status': newStatus, 'month': month}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Ödeme alındı olarak işaretlendi.'
                : 'Ödeme bekleniyor olarak işaretlendi.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  String _currentMonth() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = _currentMonth();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylık Ödeme Kontrolü',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ödeme Takip Sistemi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 48, color: Colors.orange[300]),
                  const SizedBox(height: 16),
                  const Text('Kullanıcı giriş yapmamış'),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.coachId ?? currentUser!.uid)
                  .collection('students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text('Bir hata oluştu.'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.blue),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Öğrenci bulunamadı.'),
                      ],
                    ),
                  );
                }

                var studentDocs = snapshot.data!.docs;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.blue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mevcut Dönem',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currentMonth,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: studentDocs.length,
                        itemBuilder: (context, index) {
                          var studentData = studentDocs[index];
                          String studentId = studentData.id;
                          String fullName =
                              '${studentData['firstName']} ${studentData['lastName']}';
                          String initials =
                              '${studentData['firstName'][0]}${studentData['lastName'][0]}'
                                  .toUpperCase();

                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.coachId ?? currentUser!.uid)
                                .collection('students')
                                .doc(studentId)
                                .collection('payments')
                                .doc(currentMonth)
                                .snapshots(),
                            builder: (context, paymentSnapshot) {
                              if (paymentSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              bool paymentStatus = false;
                              if (paymentSnapshot.hasData &&
                                  paymentSnapshot.data!.exists) {
                                paymentStatus =
                                    paymentSnapshot.data!.get('status') ??
                                        false;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: AppColors.blue,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: paymentStatus
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                paymentStatus
                                                    ? 'Ödeme alındı'
                                                    : 'Ödeme bekleniyor',
                                                style: TextStyle(
                                                  color: paymentStatus
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: paymentStatus,
                                        onChanged: (newValue) {
                                          _updateMonthlyPaymentStatus(studentId,
                                              currentMonth, newValue);
                                        },
                                        activeColor: AppColors.green,
                                        activeTrackColor:
                                            AppColors.green.withOpacity(0.2),
                                        inactiveThumbColor: AppColors.red.withOpacity(0.1),
                                        inactiveTrackColor:
                                            AppColors.red.withOpacity(0.5),
                                        trackOutlineColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (!paymentStatus) {
                                              return AppColors.red;
                                            }
                                            return AppColors.green;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
