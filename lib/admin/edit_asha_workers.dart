import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class EditAshaWorkerPage extends StatefulWidget {
  const EditAshaWorkerPage({super.key});

  @override
  _EditAshaWorkerPageState createState() => _EditAshaWorkerPageState();
}

class _EditAshaWorkerPageState extends State<EditAshaWorkerPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<Map<String, dynamic>> verifiedWorkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVerifiedWorkers();
  }

  Future<void> _fetchVerifiedWorkers() async {
    await _sheetsService
        .init(); // Ensure sheets are initialized before fetching
    List<Map<String, dynamic>> allWorkers =
        await _sheetsService.fetchAshaWorkers();

    setState(() {
      verifiedWorkers = allWorkers
          .where((worker) => worker['verification'] == 'verified')
          .toList();
      _isLoading = false;
    });

    print("✅ Fetched ${verifiedWorkers.length} verified ASHA workers.");
  }

  Future<void> _deleteWorker(String email) async {
    bool success = await _sheetsService.deleteAshaWorker(email);
    if (success) {
      setState(() {
        verifiedWorkers.removeWhere((worker) => worker['email'] == email);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ ASHA Worker Removed.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to remove ASHA Worker.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit ASHA Workers")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : verifiedWorkers.isEmpty
              ? const Center(child: Text("No verified ASHA workers found."))
              : ListView.builder(
                  itemCount: verifiedWorkers.length,
                  itemBuilder: (context, index) {
                    var worker = verifiedWorkers[index];
                    return ListTile(
                      title: Text(worker['name']),
                      subtitle: Text("Block: ${worker['block_number']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteWorker(worker['email']),
                      ),
                    );
                  },
                ),
    );
  }
}
