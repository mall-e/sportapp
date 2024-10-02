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

  List<String> monthsToDisplay = [];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    int currentMonthIndex = now.month - 1; // Şu anki ay indeksi (0 tabanlı)

    // Bulunduğumuz aydan yıl sonuna kadar olan ayları ekle
    monthsToDisplay = months.sublist(currentMonthIndex) + months.sublist(0, currentMonthIndex);
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
        itemCount: monthsToDisplay.length,
        itemBuilder: (context, index) {
          String monthName = monthsToDisplay[index];

          // Seçilen ayın indeksini bulalım
          int selectedMonthIndex = (DateTime.now().month - 1 + index) % 12;
          int daysInMonth = getDaysInMonth(DateTime.now().year, selectedMonthIndex + 1);

          return ListTile(
            title: Text(monthName),
            onTap: () {
              // Seçilen ayın ismi ve gün sayısını `MonthPage` sayfasına gönderiyoruz
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
          );
        },
      ),
    );
  }
}
