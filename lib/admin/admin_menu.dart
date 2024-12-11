import 'package:flutter/material.dart';
import 'package:sportapp/add_student_page.dart';
import 'package:sportapp/admin/admin_session_control_page.dart';
import 'package:sportapp/admin/coach_creation_page.dart';
import 'package:sportapp/admin/coachs_list_page.dart';
import 'package:sportapp/payment_screen.dart';
import 'package:sportapp/settings_page.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/widgets/custom_appbar.dart';

class AdminMenu extends StatefulWidget {
  const AdminMenu({super.key});

  @override
  State<AdminMenu> createState() => _AdminMenuState();
}

class _AdminMenuState extends State<AdminMenu> {
  final List<MenuOption> menuOptions = [
    MenuOption(
      title: 'Koç Ekle',
      subtitle: 'Yeni koç kaydı oluştur',
      icon: Icons.person_add_outlined,
      route: () => CoachCreationPage(),
    ),
    MenuOption(
      title: 'Koç Listesi',
      subtitle: 'Tüm koçları görüntüle ve yönet',
      icon: Icons.people_outline,
      route: () => const CoachListPage(),
    ),
    // Diğer menü seçenekleri buraya eklenebilir
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Yönetici Paneli',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: AppColors.blue),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SettingsPage();
              }));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: menuOptions.length,
                    itemBuilder: (context, index) {
                      final option = menuOptions[index];
                      return _buildMenuCard(
                        title: option.title,
                        subtitle: option.subtitle,
                        icon: option.icon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => option.route(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Function route;

  MenuOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
