import 'package:flutter/material.dart';
import 'services/google_sheets_service.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  _UserRegisterPageState createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _blockNumberController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      print("❌ Form validation failed!");
      return;
    }

    setState(() => _isLoading = true);
    print("⏳ Registering user...");

    try {
      await _googleSheetsService.insertAshaUser(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        address: _addressController.text,
        blockNumber: _blockNumberController.text,
        dob: _dobController.text,
        category: _selectedCategory ?? '',
      );

      // ✅ After inserting the new user, send notification to ASHA worker
      await _googleSheetsService.addAshaNotification(
          _blockNumberController.text,
          "${_nameController.text} registered in your block!");

      print("✅ Registration successful!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("❌ ERROR: Registration failed - $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _buildTextField(
                  _nameController, 'Name', Icons.person, 'Enter your name'),
              const SizedBox(height: 16),
              _buildTextField(
                  _emailController, 'Email', Icons.email, 'Enter a valid email',
                  isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                  'Enter your phone number',
                  isPhone: true),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Address', Icons.home,
                  'Enter your address'),
              const SizedBox(height: 16),
              _buildTextField(_blockNumberController, 'Block Number',
                  Icons.apartment, 'Enter block number'),
              const SizedBox(height: 16),
              _buildTextField(_dobController, 'Date of Birth (DD/MM/YYYY)',
                  Icons.cake, 'Enter your date of birth',
                  isDob: true),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildPasswordField(
                  _passwordController, 'Password', Icons.lock, true),
              const SizedBox(height: 16),
              _buildPasswordField(_confirmPasswordController,
                  'Confirm Password', Icons.lock_outline, false),
              const SizedBox(height: 24),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String errorMsg, {
    bool isEmail = false,
    bool isPhone = false,
    bool isDob = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: isEmail
          ? TextInputType.emailAddress
          : (isPhone
              ? TextInputType.phone
              : (isDob ? TextInputType.datetime : TextInputType.text)),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorMsg;
        }
        if (isEmail &&
            !RegExp(r'^[\w-\.]+@[\w-]+\.[a-z]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Category (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      value: _selectedCategory,
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      items: const [
        DropdownMenuItem(value: 'Under 15', child: Text('Under 15')),
        DropdownMenuItem(value: 'Pregnancy', child: Text('Pregnancy')),
        DropdownMenuItem(value: 'Choose Later', child: Text('Choose Later')),
      ],
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPasswordField,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordField
                ? (_obscurePassword ? Icons.visibility_off : Icons.visibility)
                : (_obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
          ),
          onPressed: () {
            setState(() {
              if (isPasswordField) {
                _obscurePassword = !_obscurePassword;
              } else {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }
            });
          },
        ),
      ),
      obscureText: isPasswordField ? _obscurePassword : _obscureConfirmPassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your password';
        }
        if (isPasswordField && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (!isPasswordField && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _registerUser,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: const Text('Register'),
            ),
    );
  }
}
