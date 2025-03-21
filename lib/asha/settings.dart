import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';
import '../homepage/asha_homepage.dart';

class AshaSettingsPage extends StatefulWidget {
  final String userEmail;
  const AshaSettingsPage({super.key, required this.userEmail});

  @override
  _AshaSettingsPageState createState() => _AshaSettingsPageState();
}

class _AshaSettingsPageState extends State<AshaSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isPasswordVisible = false; // ✅ Toggle visibility for new password
  bool _isConfirmPasswordVisible =
      false; // ✅ Toggle visibility for confirm password

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _id;
  String? _username;
  String? _blockNumber;
  String? _email;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _fetchAshaData();
  }

  Future<void> _fetchAshaData() async {
    try {
      var data = await GoogleSheetsService()
          .getAshaWorkerProfileDetails(widget.userEmail);

      if (data.isNotEmpty) {
        print("✅ Fetched ASHA Worker Data: $data"); // 🔍 Debug print
        setState(() {
          _id = data["id"];
          _username = data["username"];
          _nameController.text = data["name"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          _blockNumber = data["block_number"];
          _email = data["email"];
          _verificationStatus = data["verification"];
        });
      }
    } catch (e) {
      print("❌ Error fetching ASHA worker details: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    final updatedData = {
      "name": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),
    };

    await GoogleSheetsService()
        .updateAshaWorkerDetails(widget.userEmail, updatedData);

    if (_passwordController.text.isNotEmpty) {
      await GoogleSheetsService().updateAshaWorkerPassword(
        widget.userEmail,
        _passwordController.text.trim(),
      );
    }

    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ASHAHomePage(userEmail: widget.userEmail),
      ),
    );
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
                    _buildProfileField("ID", _id),
                    _buildProfileField("Username", _username),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) =>
                          value!.isEmpty ? "Enter your name" : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: "Phone"),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? "Enter your phone number" : null,
                    ),
                    const SizedBox(height: 20),

                    // Non-editable fields
                    _buildProfileField("Block Number", _blockNumber),
                    _buildProfileField("Email", _email),
                    _buildProfileField(
                        "Verification Status", _verificationStatus),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible =
                                  !_isPasswordVisible; // ✅ Toggle visibility
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible; // ✅ Toggle visibility
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return "Passwords do not match!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updateDetails,
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value ?? "N/A",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
