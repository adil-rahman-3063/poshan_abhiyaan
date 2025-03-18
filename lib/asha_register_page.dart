import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'services/google_drive_service.dart';
import 'services/google_sheets_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AshaRegisterPage extends StatefulWidget {
  const AshaRegisterPage({super.key});

  @override
  _AshaRegisterPageState createState() => _AshaRegisterPageState();
}

class _AshaRegisterPageState extends State<AshaRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _blockController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _blockController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generateCredentials() {
    final name = _nameController.text.trim();
    final block = _blockController.text.trim();
    if (name.isEmpty || block.isEmpty) return;

    final username = "$name@$block";
    final password = "$name.$block";
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });

    print(
        "✅ Credentials Generated: Username - $username, Password - $password");
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        print("✅ Manage External Storage permission granted!");
      } else {
        print("❌ Manage External Storage permission denied!");
      }
    }
  }

  Future<void> _pickFile() async {
    await _requestStoragePermission();

    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.isEmpty) {
      print("❌ File selection failed");
      return;
    }

    setState(() {
      _selectedFile = result.files.first;
      print("✅ File selected: ${_selectedFile!.name}");
    });
  }

  Future<void> _registerAshaWorker() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showErrorDialog("Please upload an ID proof.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      File file;
      if (_selectedFile!.path != null) {
        file = File(_selectedFile!.path!);
      } else if (_selectedFile!.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        file = File('${tempDir.path}/${_selectedFile!.name}');
        await file.writeAsBytes(_selectedFile!.bytes!);
      } else {
        _showErrorDialog("File selection failed, please try again.");
        setState(() => _isLoading = false);
        return;
      }

      print("📤 Uploading file: ${file.path}");

      final driveService = GoogleDriveService();
      final String? idUrl = await driveService.uploadFile(file);

      if (idUrl == null || idUrl.isEmpty) {
        _showErrorDialog("ID proof upload failed. Please try again.");
        setState(() => _isLoading = false);
        return;
      }

      final googleSheetsService = GoogleSheetsService();
      await googleSheetsService.insertAshaWorker(
        name: _nameController.text,
        phone: _phoneController.text,
        blockNumber: _blockController.text,
        email: _emailController.text,
        idUrl: idUrl,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Registration successful')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Registration failed: $e");
      _showErrorDialog("Registration failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error ❌'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, String errorMsg,
      {bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      readOnly: isReadOnly,
      validator: (value) => value!.isEmpty ? errorMsg : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ASHA Worker Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Full Name', Icons.person,
                  'Please enter name'),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                  'Please enter phone number'),
              const SizedBox(height: 16),
              _buildTextField(_blockController, 'Block Number', Icons.apartment,
                  'Please enter block number'),
              const SizedBox(height: 16),
              _buildTextField(
                  _emailController, 'Email', Icons.email, 'Please enter email'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateCredentials,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text("Generate Credentials"),
              ),
              const SizedBox(height: 16),
              _buildTextField(_usernameController, 'Username',
                  Icons.person_outline, 'Username required',
                  isReadOnly: true),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Password', Icons.lock,
                  'Password required',
                  isReadOnly: true),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child: Text(_selectedFile == null
                    ? "Upload ID Proof"
                    : "File Selected: ${_selectedFile!.name}"),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerAshaWorker,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
