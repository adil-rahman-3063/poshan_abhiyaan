import 'package:flutter/material.dart';
import 'login_page.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poshan Abhaya',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(), // Start directly at the login page
    );
  }
}
