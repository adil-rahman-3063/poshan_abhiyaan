import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class UserNotificationsPage extends StatefulWidget {
  final String userEmail;

  const UserNotificationsPage({super.key, required this.userEmail});

  @override
  _UserNotificationsPageState createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true; // ✅ Added loading state

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // ✅ Fetch notifications from "user_notification" filtered by email
  Future<void> _fetchNotifications() async {
    try {
      print("⏳ Fetching notifications...");
      List<Map<String, dynamic>> fetchedNotifications =
          await GoogleSheetsService().getUserNotifications(widget.userEmail);

      setState(() {
        _notifications = fetchedNotifications;
        _isLoading = false; // ✅ Stop loading after fetching
      });

      print("✅ Notifications fetched: $_notifications");
    } catch (e) {
      print("❌ Error fetching notifications: $e");
      setState(() => _isLoading = false); // ✅ Stop loading on error
    }
  }

  // ✅ Mark as Read (delete row from Google Sheets)
  Future<void> _markAsRead(int index) async {
    try {
      String email = _notifications[index]['email'];
      String message = _notifications[index]['message'];

      await GoogleSheetsService().deleteUserNotification(email, message);

      setState(() {
        _notifications.removeAt(index);
      });

      print("✅ Notification marked as read: $message");
    } catch (e) {
      print("❌ Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Show loading
          : _notifications.isEmpty
              ? const Center(
                  child:
                      Text("No new notifications.")) // ✅ Show only if no data
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.notifications, color: Colors.blue),
                        title: Text(_notifications[index]['message']),
                        trailing: TextButton(
                          onPressed: () => _markAsRead(index),
                          child: const Text("Mark as Read",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
