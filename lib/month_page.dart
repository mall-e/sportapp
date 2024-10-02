import 'package:flutter/material.dart';
import 'package:sportapp/months.dart';
import 'package:sportapp/roll_call_page.dart';

class MonthPage extends StatelessWidget {
  final String monthName;
  final int daysInMonth;

  const MonthPage(
      {super.key, required this.monthName, required this.daysInMonth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Months()));
          },
          child: Text(monthName),
        ),
      ),
      body: GridView.builder(
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
                  DateTime(DateTime.now().year, DateTime.now().month, day);
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
    );
  }
}
