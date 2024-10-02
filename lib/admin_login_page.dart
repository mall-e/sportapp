
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sportapp/main.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _auth = FirebaseAuth.instance; // Firebase Auth instance
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // To show a loading indicator during login

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Firebase email & password ile giriş yapma
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Giriş başarılı olduğunda MainMenu'ya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainMenu()),
      );
    } on FirebaseAuthException catch (e) {
      // Giriş başarısız olduğunda hata mesajı göster
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'Kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        message = 'Hatalı şifre girdiniz.';
      } else {
        message = 'Giriş başarısız oldu: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Girişi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Giriş Yap'),
                  ),
          ],
        ),
      ),
    );
  }
}