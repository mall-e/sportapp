import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportapp/models/coach_model.dart';

class CoachProfilePage extends StatefulWidget {
  final String coachId;

  const CoachProfilePage({super.key, required this.coachId});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  bool isEditing = false;
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
    setState(() => isEditing = false);
  }

  void _addBranchToFirestore(String branch) async {
    // Firestore'da branches array'ine yeni branşı ekler
    await FirebaseFirestore.instance.collection('users').doc(widget.coachId).update({
      'branches': FieldValue.arrayUnion([branch]),
    });
  }

  void _addBranch() {
    if (branchController?.text.isNotEmpty ?? false) {
      setState(() {
        branches.add(branchController!.text);
      });
      _addBranchToFirestore(branchController!.text); // Firestore'a ekle
      branchController?.clear();
    }
  }

  void _removeBranch(int index) async {
    String branchToRemove = branches[index];
    setState(() {
      branches.removeAt(index);
    });
    // Firestore'da branches array'inden bu branşı çıkar
    await FirebaseFirestore.instance.collection('users').doc(widget.coachId).update({
      'branches': FieldValue.arrayRemove([branchToRemove]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koç Profili'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                saveChanges(Coach(
                  id: widget.coachId,
                  firstName: firstNameController?.text ?? '',
                  lastName: lastNameController?.text ?? '',
                  email: emailController?.text ?? '',
                  profilePictureUrl: '',
                  branches: branches,
                ));
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coach.profilePictureUrl != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(coach.profilePictureUrl!),
                  ),
                const SizedBox(height: 16),
                if (isEditing)
                  Column(
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(labelText: 'İsim'),
                      ),
                      TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(labelText: 'Soyisim'),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: branchController,
                              decoration: const InputDecoration(labelText: 'Branş'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addBranch,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...branches.map((branch) {
                        int index = branches.indexOf(branch);
                        return ListTile(
                          title: Text(branch),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeBranch(index),
                          ),
                        );
                      }).toList(),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${coach.firstName} ${coach.lastName}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coach.email,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Branşlar:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (branches.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: branches.map((branch) => Text('- $branch')).toList(),
                        )
                      else
                        const Text('Branş bilgisi yok.'),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
