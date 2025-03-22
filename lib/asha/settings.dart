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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
        print("✅ Fetched ASHA Worker Data: $data");
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
          widget.userEmail, _passwordController.text.trim());
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
                    _buildTextField("ID", _id, isEditable: false),
                    _buildTextField("Username", _username, isEditable: false),
                    _buildTextField("Name", _nameController),
                    _buildTextField("Phone", _phoneController,
                        keyboardType: TextInputType.phone),
                    _buildTextField("Block Number", _blockNumber,
                        isEditable: false),
                    _buildTextField("Email", _email, isEditable: false),
                    _buildTextField("Verification Status", _verificationStatus,
                        isEditable: false),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                        "New Password", _passwordController, _isPasswordVisible,
                        () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    }),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                        "Confirm Password",
                        _confirmPasswordController,
                        _isConfirmPasswordVisible, () {
                      setState(() => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible);
                    }),
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

  Widget _buildTextField(String label, dynamic valueOrController,
      {bool isEditable = true,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: valueOrController is TextEditingController
            ? valueOrController
            : null,
        initialValue: valueOrController is String ? valueOrController : null,
        readOnly: !isEditable,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !isEditable,
          fillColor: !isEditable ? Colors.grey[200] : null,
        ),
        validator: (value) =>
            (isEditable && (value == null || value.trim().isEmpty))
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
          if (controller == _passwordController &&
              _confirmPasswordController.text.isNotEmpty &&
              value != _confirmPasswordController.text) {
            return "Passwords do not match!";
          }
          return null;
        },
      ),
    );
  }
}
