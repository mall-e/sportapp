import 'package:flutter/material.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/settings_page.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const CustomAppbar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title ?? "",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Başlık rengi beyaz
        ),
      ),
      centerTitle: true, // Başlığı ortalar
      backgroundColor: AppColors.blue, // Arka plan rengini mavi yapar
      elevation: 4, // Hafif bir gölge verir
      actions: [
        IconButton(
          icon: const Icon(Icons.settings,color: Colors.black,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ],
       shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16), // Alt kısmı yuvarlak yapar
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
