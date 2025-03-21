import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/google_sheets_service.dart';
import '../asha/settings.dart';

class AshaProfilePage extends StatefulWidget {
  final String userEmail;
  const AshaProfilePage({super.key, required this.userEmail});

  @override
  _AshaProfilePageState createState() => _AshaProfilePageState();
}

class _AshaProfilePageState extends State<AshaProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _ashaData; // ✅ Store ASHA worker details

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
          _ashaData = data;
        });
      } else {
        print("❌ No data found for user: ${widget.userEmail}");
      }
    } catch (e) {
      print("❌ Error fetching ASHA worker details: $e");
    }
    setState(() => _isLoading = false);
  }

  void _viewId() async {
    final url = _ashaData?["id_url"];
    if (url != null && url.isNotEmpty) {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        print("❌ Could not open ID URL: $url");
      }
    } else {
      print("❌ No ID document available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ASHA Worker Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ashaData == null
              ? const Center(child: Text("ASHA Worker data not found!"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileField("ID", _ashaData!["id"]),
                      _buildProfileField("Name", _ashaData!["name"]),
                      _buildProfileField("Phone", _ashaData!["phone"]),
                      _buildProfileField(
                          "Block Number", _ashaData!["block_number"]),
                      _buildProfileField("Email", _ashaData!["email"]),
                      _buildProfileField("Username", _ashaData!["username"]),
                      _buildProfileField(
                          "Verification Status", _ashaData!["verification"]),
                      const SizedBox(height: 10),

                      // View ID Button
                      if (_ashaData!["id_url"] != null &&
                          _ashaData!["id_url"].isNotEmpty)
                        Center(
                          child: ElevatedButton(
                            onPressed: _viewId,
                            child: const Text("View ID Document"),
                          ),
                        ),

                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AshaSettingsPage(
                                    userEmail: widget.userEmail),
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
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // ✅ Rounded Box
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value?.isNotEmpty == true ? value! : "N/A",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
