import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/admin_session_control_page.dart';
import 'package:sportapp/admin/coach_creation_page.dart';
import 'package:sportapp/admin/coachs_list_page.dart';
import 'package:sportapp/widgets/custom_appbar.dart';

class AdminMenu extends StatefulWidget {
  const AdminMenu({super.key});

  @override
  State<AdminMenu> createState() => _AdminMenuState();
}

class _AdminMenuState extends State<AdminMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: 'Admin Menu',),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Öğrenci Ekle'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachListPage(whichCase: 3,)));
            },
          ),
          ListTile(
            title: const Text('Öğrenci Listesi'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachListPage(whichCase: 0,)));
            },
          ),
          ListTile(
            title: const Text('Koç Ekle'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachCreationPage()));
            },
          ),
          ListTile(
            title: const Text('Koç Listesi'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachListPage(whichCase: 1,)));
            },
          ),
          ListTile(
            title: const Text('Yoklama Düzenleme'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachListPage(whichCase: 2,)));
            },
          ),
          ListTile(
            title: const Text('Koç Seans Düzenleme'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachListPage(whichCase: 4,)));
            },
          ),
        ],
      )
    );
  }
}
