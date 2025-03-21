import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class AshaNotificationPage extends StatefulWidget {
  final String userEmail;
  const AshaNotificationPage({Key? key, required this.userEmail})
      : super(key: key);

  @override
  _AshaNotificationPageState createState() => _AshaNotificationPageState();
}

class _AshaNotificationPageState extends State<AshaNotificationPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<Map<String, String>> _notifications = [];
  bool _isLoading = true;
  String? _ashaWorkerBlock;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    _ashaWorkerBlock =
        await _sheetsService.getAshaWorkerBlockNumber(widget.userEmail);

    if (_ashaWorkerBlock == null) {
      print("❌ ASHA worker block not found!");
      setState(() => _isLoading = false);
      return;
    }

    print("⏳ Fetching notifications for block: $_ashaWorkerBlock");

    // ✅ Fetch notifications and convert values to String
    List<Map<String, dynamic>> rawNotifications =
        await _sheetsService.fetchAshaNotifications(widget.userEmail);

    _notifications = rawNotifications
        .map((notification) => notification.map(
              (key, value) =>
                  MapEntry(key, value.toString()), // ✅ Convert to String
            ))
        .toList();

    setState(() => _isLoading = false);
    print("✅ Notifications fetched: $_notifications");
  }

  Future<void> _deleteNotification(int index) async {
    if (index < 0 || index >= _notifications.length) {
      print("❌ Invalid index: $index");
      return;
    }

    String messageToDelete = _notifications[index]["message"] ?? "";
    print("⏳ Deleting notification: $messageToDelete");

    await _sheetsService.deleteAshaNotification(index + 1);

    // Refresh notifications after deletion
    if (mounted) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text('No new notifications!',
                      style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                            _notifications[index]["message"] ?? "Notification"),
                        subtitle: Text(_notifications[index]["date"] ?? ""),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNotification(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
