import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/models/coach_model.dart';
import 'package:sportapp/widgets/colors.dart';
import 'package:sportapp/widgets/custom_appbar.dart';

class CoachProfilePage extends StatefulWidget {
  final String coachId;

  const CoachProfilePage({super.key, required this.coachId});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  TextEditingController? firstNameController;
  TextEditingController? lastNameController;
  TextEditingController? emailController;
  TextEditingController? branchController;
  List<String> branches = [];

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    branchController = TextEditingController();
  }

  @override
  void dispose() {
    firstNameController?.dispose();
    lastNameController?.dispose();
    emailController?.dispose();
    branchController?.dispose();
    super.dispose();
  }

  Future<void> saveChanges(Coach coach) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.coachId).update({
      'firstName': firstNameController?.text ?? coach.firstName,
      'lastName': lastNameController?.text ?? coach.lastName,
      'email': emailController?.text ?? coach.email,
      'branches': branches,
    });
  }

  void _addBranchToFirestore(String branch) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.coachId).update({
      'branches': FieldValue.arrayUnion([branch]),
    });
  }

  void _addBranch() {
    if (branchController?.text.isNotEmpty ?? false) {
      setState(() {
        branches.add(branchController!.text);
      });
      _addBranchToFirestore(branchController!.text);
      branchController?.clear();
    }
  }

  void _removeBranch(int index) async {
    String branchToRemove = branches[index];
    setState(() {
      branches.removeAt(index);
    });
    await FirebaseFirestore.instance.collection('users').doc(widget.coachId).update({
      'branches': FieldValue.arrayRemove([branchToRemove]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      appBar: CustomAppbar(
        title: 'Koç Profili',
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.coachId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Koç bilgisi bulunamadı.'));
          }

          Coach coach = Coach.fromFirestore(snapshot.data!);
          firstNameController?.text = coach.firstName;
          lastNameController?.text = coach.lastName;
          emailController?.text = coach.email;
          branches = coach.branches;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.blue,
                        child: Text(
                          coach.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: firstNameController!,
                        label: 'İsim',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: lastNameController!,
                        label: 'Soyisim',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: emailController!,
                        label: 'Email',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: branchController!,
                              label: 'Yeni Branş Ekle',
                              icon: Icons.sports,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addBranch,
                            color: AppColors.blue,
                            iconSize: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Branşlar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (branches.isEmpty)
                        Center(
                          child: Text(
                            'Henüz branş eklenmemiş',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: branches.map((branch) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    branch,
                                    style: TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeBranch(branches.indexOf(branch)),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            saveChanges(coach);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Değişiklikler kaydedildi'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}