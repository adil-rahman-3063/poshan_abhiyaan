import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class AdminNotificationPage extends StatefulWidget {
  @override
  _AdminNotificationPageState createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<String> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  /// ✅ Fetch Notifications from Google Sheets
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    final notifications = await _sheetsService.fetchAdminNotifications();

    setState(() {
      _notifications =
          notifications.map((row) => row.isNotEmpty ? row[0] : '').toList();
      _isLoading = false;
    });
  }

  /// ✅ Delete a Notification
  Future<void> _deleteNotification(int index) async {
    await _sheetsService.deleteAdminNotification(index);
    _fetchNotifications(); // Refresh list after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Notifications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner
          : _notifications.isEmpty
              ? Center(
                  child:
                      Text('No Notifications', style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(_notifications[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNotification(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
