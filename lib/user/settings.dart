import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class SettingsPage extends StatefulWidget {
  final String userEmail;
  const SettingsPage({super.key, required this.userEmail});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, dynamic>? _userData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      var data = await GoogleSheetsService().getUserDetails(widget.userEmail);
      setState(() {
        _userData = data;
        _isLoading = false;
      });

      // Pre-fill text controllers with existing data
      _nameController.text = data["name"] ?? "";
      _phoneController.text = data["phone"] ?? "";
      _addressController.text = data["address"] ?? "";
      _dobController.text = data["dob"] ?? "";
    } catch (e) {
      print("❌ Error fetching user settings data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      await GoogleSheetsService().updateUserDetails(widget.userEmail, {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "dob": _dobController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      print("❌ Error updating user details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile.")),
      );
    }

    setState(() => _isUpdating = false);
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password cannot be empty!")),
      );
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await GoogleSheetsService().updateUserPassword(
        widget.userEmail,
        _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );
    } catch (e) {
      print("❌ Error changing password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to change password.")),
      );
    }

    setState(() => _isUpdating = false);
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField("Name", _nameController),
                    _buildTextField("Phone", _phoneController,
                        keyboardType: TextInputType.phone),
                    _buildTextField("Address", _addressController),
                    _buildTextField("Date of Birth", _dobController),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updateUserDetails,
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text("Update Profile"),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),

                    // New Password Field with Eye Icon
                    _buildPasswordField(
                        "New Password", _passwordController, _obscurePassword,
                        () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    }),

                    const SizedBox(height: 10),

                    // Confirm Password Field with Eye Icon
                    _buildPasswordField(
                        "Confirm Password",
                        _confirmPasswordController,
                        _obscureConfirmPassword, () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    }),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: _isUpdating ? null : _changePassword,
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text("Change Password"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? "$label cannot be empty"
            : null,
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      bool obscureText, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleVisibility,
          ),
        ),
        validator: (value) {
          if (label == "Confirm Password" &&
              _passwordController.text.isNotEmpty) {
            if (value != _passwordController.text) {
              return "Passwords do not match!";
            }
          }
          return null;
        },
      ),
    );
  }
}
