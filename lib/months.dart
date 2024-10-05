import 'package:flutter/material.dart';
import 'package:sportapp/month_page.dart';

class Months extends StatefulWidget {
  const Months({super.key});

  @override
  State<Months> createState() => _MonthsState();
}

class _MonthsState extends State<Months> {
  List<String> months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  void initState() {
    super.initState();
  }

  // Ayın gün sayısını dinamik olarak hesaplayan fonksiyon
  int getDaysInMonth(int year, int month) {
    // Bir sonraki ayın ilk gününden bir gün geri giderek o ayın son gününü buluyoruz
    DateTime nextMonth = DateTime(year, month + 1, 0);
    return nextMonth.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ay Seçimi'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: months.length,
        itemBuilder: (context, index) {
          String monthName = months[index];

          // Seçilen ayın indeksini bulalım
          int selectedMonthIndex = (DateTime.now().month - 1 + index) % 12;
          int daysInMonth = getDaysInMonth(DateTime.now().year, selectedMonthIndex + 1);

          return ListTile(
            title: Text(monthName),
            onTap: () {
              // Mevcut BottomSheet'i kapatıp yeni BottomSheet açıyoruz
              Navigator.pop(context); // Mevcut bottom sheet'i kapat

              // Yeni BottomSheet olarak MonthPage'i açıyoruz
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return MonthPage(
                    monthName: monthName,
                    selectedMonth: index + 1,
                    daysInMonth: daysInMonth,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
