import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachCreationPage extends StatefulWidget {
  const CoachCreationPage({super.key});

  @override
  _CoachCreationPageState createState() => _CoachCreationPageState();
}

class _CoachCreationPageState extends State<CoachCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool _isLoading = false;
  String? _adminEmail;
  String? _adminPassword;

  @override
  void initState() {
    super.initState();
    // Admin'in oturum açma bilgilerini sakla
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _adminEmail = currentUser.email;
      // Admin şifresini manuel olarak saklayın (veya güvenli bir şekilde elde edin)
      _adminPassword = "your_admin_password"; // Bu şifreyi manuel olarak alın veya güvenli bir şekilde saklayın
    }
  }

  Future<void> _createCoach() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Yeni bir koç oluştur
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Yeni oluşturulan kullanıcının UID'sini alın
        User? newUser = FirebaseAuth.instance.currentUser;

        if (newUser != null) {
          await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': 'coach',
          });
        }

        // Yeni kullanıcı oluşturulduktan sonra admin kullanıcıya geri dön
        if (_adminEmail != null && _adminPassword != null) {
          await FirebaseAuth.instance.signOut(); // Yeni oluşturulan kullanıcıyı çıkış yap
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _adminEmail!,
            password: _adminPassword!,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koç başarıyla oluşturuldu.')),
        );

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.message}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koç Oluştur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Adı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Soyadı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyadı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta girin';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Geçerli bir e-posta girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createCoach,
                      child: const Text('Koç Oluştur'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
