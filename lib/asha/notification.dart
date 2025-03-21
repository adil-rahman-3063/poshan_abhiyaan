import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class AshaNotificationPage extends StatefulWidget {
  final String ashaWorkerBlock;
  const AshaNotificationPage({Key? key, required this.ashaWorkerBlock})
      : super(key: key);

  @override
  _AshaNotificationPageState createState() => _AshaNotificationPageState();
}

class _AshaNotificationPageState extends State<AshaNotificationPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<Map<String, String>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final notifications =
        await _sheetsService.fetchAshaNotifications(widget.ashaWorkerBlock);
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _deleteNotification(int index) async {
    await _sheetsService.deleteAshaNotification(index);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
