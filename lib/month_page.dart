import 'package:flutter/material.dart';
import 'package:sportapp/months.dart';
import 'package:sportapp/roll_call_page.dart';

class MonthPage extends StatelessWidget {
  final String monthName;
  final int daysInMonth;
  final int selectedMonth;

  const MonthPage(
      {super.key, required this.monthName, required this.daysInMonth, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          leading: TextButton(
            onPressed: () {
              // Aktif olan bottom sheet'i kapatıp yenisini açıyoruz
              Navigator.pop(context); // Mevcut bottomsheet'i kapat
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return const Months(); // Months bottomsheet'i aç
                },
              );
            },
            child: Text(monthName),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // Haftanın 7 günü için 7 sütun
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1; // Günler 1'den başlar

              return GestureDetector(
                onTap: () {
                  // Tıklanan günün tarihini RollCallPage'e gönderiyoruz
                  DateTime selectedDate =
                      DateTime(DateTime.now().year, selectedMonth, day);
                  Navigator.pop(context); // Mevcut bottomsheet'i kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RollCallPage(selectedDate: selectedDate),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day', // Gün numarası
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
