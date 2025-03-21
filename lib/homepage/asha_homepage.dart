import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../asha/manage_user.dart';
import '../asha/calendar.dart';
import '../asha/notification.dart';
import '../services/google_sheets_service.dart';
import '../asha/profile.dart';

class ASHAHomePage extends StatefulWidget {
  final String userEmail;
  const ASHAHomePage({super.key, required this.userEmail});

  @override
  _ASHAHomePageState createState() => _ASHAHomePageState();
}

class _ASHAHomePageState extends State<ASHAHomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchAshaWorkerDetails();
    _fetchRecentNotifications();
  }

  Future<void> _fetchAshaWorkerDetails() async {
    try {
      await GoogleSheetsService().getAshaWorkerDetails(widget.userEmail);
      setState(() => _isLoading = false);
    } catch (e) {
      print("❌ Error fetching ASHA details: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecentNotifications() async {
    try {
      List<Map<String, dynamic>> notifications =
          await GoogleSheetsService().fetchAshaNotifications(widget.userEmail);

      if (notifications.isNotEmpty) {
        setState(() {
          _recentNotifications = notifications.take(2).toList(); // Get latest 2
        });
      }
    } catch (e) {
      print("❌ Error fetching recent notifications: $e");
    }
  }

  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    if (hour >= 17 && hour < 21) return "Good Evening";
    return "Good Night";
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentDate =
        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poshan Abhiyaan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AshaNotificationPage(userEmail: widget.userEmail),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            getGreeting(),
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentDate,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔔 Recent Notifications Section
                    const Text(
                      "Recent Notifications",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _recentNotifications.isEmpty
                          ? const Center(
                              child: Text(
                                "No new notifications!",
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentNotifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    _recentNotifications[index];
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.brown, width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "📌 ${notification["message"] ?? "Notification"}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification["timestamp"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // 🔳 Buttons Grid (2x2)
                    GridView.count(
                      shrinkWrap:
                          true, // Prevents overflow inside SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling for GridView
                      crossAxisCount: 2,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                      childAspectRatio: 1.2,
                      children: [
                        _buildButton(Icons.group, "Manage Users"),
                        _buildButton(Icons.calendar_today, "Calendar"),
                        _buildButton(Icons.task, "Tasks"),
                        _buildButton(Icons.person, "Profile"),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Manage Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[400],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () {
        if (label == "Manage Users") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageUsersPage(userEmail: widget.userEmail),
            ),
          );
        }
        if (label == "Calendar") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarPage(userEmail: widget.userEmail),
            ),
          );
        }
        if (label == "Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AshaProfilePage(userEmail: widget.userEmail),
            ),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
