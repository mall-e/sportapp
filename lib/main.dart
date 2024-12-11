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
import 'package:sportapp/settings_page.dart';
import 'package:sportapp/student_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportapp/widgets/colors.dart';

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
        // Ana renk şemasını AppColors.blue ile uyumlu olacak şekilde ayarla
        colorScheme: ColorScheme.light(
          primary: AppColors.blue,
          secondary: AppColors.lightBlue,
          // Card ve diğer yüzeylerin rengi
          surface: Colors.white,
          background: Colors.grey[100]!,
          // Metin renkleri
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // AppBar teması
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Bottom Navigation Bar teması
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),

        // Elevated Button teması
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        // Input Decoration teması
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.blue),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const AuthCheck(),
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
                  return MainMenu(userRole: role ?? 'coach'); // Diğer roller için MainMenu'ye yönlendir
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
  final String userRole; // Yeni eklenen role parametresi
  const MainMenu({super.key, this.userRole = 'coach'}); // Varsayılan değer coach

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
    StudentListPage(
      coachId: currentCoachId,
      showBackButton: widget.userRole == 'admin', // Admin ise true, değilse false
    ),
    RollCallPage(
      selectedDate: DateTime.now(),
      coachId: currentCoachId,
      showBackButton: widget.userRole == 'admin',
    ),
    CoachsProgramPage(
      showBackButton: widget.userRole == 'admin',
    ),
    AddStudentPage(
      coachId: currentCoachId,
      showBackButton: widget.userRole == 'admin',
    ),
    SettingsPage(),
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
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Öğrenciler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check),
            label: 'Yoklama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Program',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_outlined),
            activeIcon: Icon(Icons.person_add),
            label: 'Öğrenci Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ayarlar',
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
