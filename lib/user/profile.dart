import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';
import '../user/settings.dart';

class UserProfilePage extends StatefulWidget {
  final String userEmail;
  const UserProfilePage({super.key, required this.userEmail});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

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
    } catch (e) {
      print("❌ Error fetching user profile data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text("User data not found!"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileField("Name", _userData!["name"]),
                      _buildProfileField("Phone", _userData!["phone"]),
                      _buildProfileField("Email", _userData!["email"]),
                      _buildProfileField("Address", _userData!["address"]),
                      _buildProfileField(
                          "Block Number", _userData!["block_number"]),
                      _buildProfileField("Date of Birth", _userData!["dob"]),
                      _buildProfileField("Category", _userData!["category"]),
                      _buildProfileField("Age", _userData!["age"]),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SettingsPage(userEmail: widget.userEmail),
                              ),
                            );
                          },
                          child: const Text("Go to Settings"),
                        ),
                      ),
                    ],
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
