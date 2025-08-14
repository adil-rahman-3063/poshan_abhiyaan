import 'package:flutter/material.dart';
import 'user_register_page.dart';
import 'asha_register_page.dart';
import 'services/google_sheets_service.dart';
import 'homepage/admin_homepage.dart'; // ✅ Import Admin HomePage
import 'package:phone_email_auth/phone_email_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // 🔹 Loading state
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();

    @override
  void initState() {
    super.initState();
    PhoneEmail.initializeApp(clientId: '11357085848712296301'); // Initialize here
  }

  /// ✅ **Login Function with Loading Indicator & Admin Check**
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // 🔄 Start loading

    String identifier = _identifierController.text.trim();
    String password = _passwordController.text.trim();

    // ✅ Check if Admin
    bool isAdmin = await _googleSheetsService.authenticateAdmin(
      identifier: identifier,
      password: password,
    );

    if (isAdmin) {
      print("🔹 Redirecting to Admin HomePage...");
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => AdminHomePage(adminEmail: identifier)),
      );
      return;
    }

    // ✅ Get correct email if identifier is a username
    String? email = await _googleSheetsService.getEmailByUsername(identifier);

    if (email == null) {
      print("❌ Error: Email not found for username $identifier");
      setState(() => _isLoading = false);
      return;
    }

    // ✅ Regular Login with Email
    await _googleSheetsService.login(context, email, password);

    setState(() => _isLoading = false); // ✅ Stop loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'NUTRITION AND HEALTH TRACKING',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                /// 🔹 **Identifier Input**
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email / Phone / Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your identifier'
                      : null,
                ),
                const SizedBox(height: 20),

                /// 🔹 **Password Input**
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your password'
                      : null,
                ),
                const SizedBox(height: 20),

                /// 🔹 **Login Button with Loading Indicator**
                ElevatedButton(
                  onPressed: _isLoading ? null : _login, // Disable when loading
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 20),

                /// 🔹 **Register Links**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const UserRegisterPage()));
                            },
                      child: const Text('User Register'),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AshaRegisterPage()));
                            },
                      child: const Text('ASHA Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
