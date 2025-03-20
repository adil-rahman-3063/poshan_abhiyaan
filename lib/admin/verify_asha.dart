import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyAshaPage extends StatefulWidget {
  const VerifyAshaPage({super.key});

  @override
  _VerifyAshaPageState createState() => _VerifyAshaPageState();
}

class _VerifyAshaPageState extends State<VerifyAshaPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<Map<String, dynamic>> pendingWorkers = [];
  bool _isLoading = true;
  String? selectedWorkerIdUrl;
  String? selectedWorkerEmail;

  @override
  void initState() {
    super.initState();
    _fetchPendingWorkers();
  }

  Future<void> _fetchPendingWorkers() async {
    await _sheetsService
        .init(); // Ensure sheets are initialized before fetching
    List<Map<String, dynamic>> allWorkers =
        await _sheetsService.fetchAshaWorkers();

    setState(() {
      pendingWorkers = allWorkers
          .where((worker) => worker['verification'] != 'verified')
          .toList();
      _isLoading = false;
    });

    print("✅ Fetched ${pendingWorkers.length} pending ASHA workers.");
  }

  Future<void> _verifyWorker(String email) async {
    bool success =
        await _sheetsService.updateAshaWorkerVerification(email, "verified");
    if (success) {
      setState(() {
        pendingWorkers.removeWhere((worker) => worker['email'] == email);
        selectedWorkerIdUrl = null;
        selectedWorkerEmail = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ ASHA Worker Verified!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to verify ASHA Worker.")),
      );
    }
  }

  Future<void> _rejectWorker(String email) async {
    bool success = await _sheetsService.deleteAshaWorker(email);
    if (success) {
      setState(() {
        pendingWorkers.removeWhere((worker) => worker['email'] == email);
        selectedWorkerIdUrl = null;
        selectedWorkerEmail = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ ASHA Worker Rejected & Removed.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to remove ASHA Worker.")),
      );
    }
  }

  void _showIdDocument(String? idUrl, String email) {
    if (idUrl == null || idUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No ID document found.")),
      );
      return;
    }

    // Construct the correct Google Drive link
    final String driveUrl = "https://drive.google.com/file/d/$idUrl/view";

    setState(() {
      selectedWorkerIdUrl = driveUrl;
      selectedWorkerEmail = email;
    });

    // Show a bottom sheet with options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Uploaded ID Document:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text("View ID"),
                onPressed: () async {
                  final Uri url = Uri.parse(driveUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("❌ Could not open ID document.")),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: selectedWorkerEmail != null
                        ? () => _verifyWorker(selectedWorkerEmail!)
                        : null,
                    child: const Text("Verify"),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: selectedWorkerEmail != null
                        ? () => _rejectWorker(selectedWorkerEmail!)
                        : null,
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify ASHA Workers")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // ✅ Makes the page scrollable
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true, // ✅ Fixes layout inside Column
                    physics:
                        const NeverScrollableScrollPhysics(), // ✅ Avoids nested scrolling issues
                    itemCount: pendingWorkers.length,
                    itemBuilder: (context, index) {
                      var worker = pendingWorkers[index];
                      return ListTile(
                        title: Text(worker['name']),
                        subtitle: Text("Block: ${worker['block_number']}"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showIdDocument(worker['id_url'], worker['email']),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
