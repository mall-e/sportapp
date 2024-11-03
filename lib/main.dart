import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin_login_page.dart';
import 'package:sportapp/attendant_menu.dart';
import 'package:sportapp/admin/admin_menu.dart'; // AdminMenu sayfasını ekledik
import 'package:sportapp/coachs_program_page.dart';
import 'package:sportapp/firebase_options.dart';
import 'package:sportapp/roll_call_page.dart';
import 'package:sportapp/routes/app_routes.dart';
import 'package:sportapp/student_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const AuthCheck(), // Başlangıç sayfası AuthCheck oldu
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  Future<String?> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['role'] as String?;
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // Kullanıcı oturumu açmışsa rolünü kontrol et
          return FutureBuilder<String?>(
            future: getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (roleSnapshot.hasData) {
                final role = roleSnapshot.data;

                if (role == 'admin') {
                  return const AdminMenu(); // Rol 'admin' ise AdminMenu'ya yönlendir
                } else if (role == 'attendant') {
                  return const AttendantMenu(); // Rol 'attendant' ise AttendantMenu'ya yönlendir
                } else {
                  return const MainMenu(); // Diğer roller için MainMenu'ye yönlendir
                }
              } else {
                return const AdminLoginPage(); // Rol bulunamazsa veya oturum açılmamışsa AdminLoginPage'e yönlendir
              }
            },
          );
        } else {
          return const AdminLoginPage(); // Kullanıcı giriş yapmamışsa AdminLoginPage'e yönlendir
        }
      },
    );
  }
}
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  String? currentCoachId;

  @override
  void initState() {
    super.initState();
    // Mevcut kullanıcının ID'sini al
    currentCoachId = FirebaseAuth.instance.currentUser?.uid;
  }

  late final List<Widget> _pages = <Widget>[
    StudentListPage(),
    RollCallPage(
      selectedDate: DateTime.now(),
      coachId: currentCoachId, // Koç ID'sini gönder
    ),
    CoachsProgramPage(),
    AddStudentPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.roller_shades),
            label: 'Yoklama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_month),
            label: 'Coach Program',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Student',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}