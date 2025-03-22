import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../asha/manage_user.dart';
import '../asha/calendar.dart';
import '../asha/notification.dart';
import '../asha/profile.dart';
import '../asha/pregnant.dart'; // ✅ Added import for Pregnant Page
import '../services/google_sheets_service.dart';
import '../user/feedback.dart';

class ASHAHomePage extends StatefulWidget {
  final String userEmail;
  const ASHAHomePage({super.key, required this.userEmail});

  @override
  _ASHAHomePageState createState() => _ASHAHomePageState();
}

class _ASHAHomePageState extends State<ASHAHomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isNotificationLoading = true; // ✅ Track notification loading
  bool _isButtonLoading = false;
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
    } catch (e) {
      print("❌ Error fetching ASHA details: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchRecentNotifications() async {
    try {
      List<Map<String, dynamic>> notifications =
          await GoogleSheetsService().fetchAshaNotifications(widget.userEmail);

      if (notifications.isNotEmpty) {
        setState(() {
          _recentNotifications = notifications.take(2).toList();
        });
      }
    } catch (e) {
      print("❌ Error fetching recent notifications: $e");
    }
    setState(() => _isNotificationLoading = false); // ✅ Stop loading
  }

  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    if (hour >= 17 && hour < 21) return "Good Evening";
    return "Good Night";
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _navigateToPage(index);
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageUsersPage(userEmail: widget.userEmail),
          ),
        );
        break;
      case 1:
        // Dashboard is the homepage, so no navigation needed.
        // We are already on the dashboard.
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AshaProfilePage(userEmail: widget.userEmail),
          ),
        );
        break;
    }
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
          ? const Center(
              child:
                  CircularProgressIndicator()) // ✅ Show loading while fetching
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
                      child: _isNotificationLoading
                          ? const Center(
                              child:
                                  CircularProgressIndicator(), // ✅ Show loading
                            )
                          : (_recentNotifications.isEmpty
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
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
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
                                )),
                    ),

                    const SizedBox(height: 20),

                    // 🔳 Buttons Grid (2x2)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                      childAspectRatio: 1.2,
                      children: [
                        _buildButton(Icons.group, "Manage Users"),
                        _buildButton(Icons.calendar_today, "Calendar"),
                        _buildButton(Icons.pregnant_woman,
                            "Pregnant Women"), // ✅ Added New Button
                        _buildButton(Icons.person, "Profile"),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown[400],
        child: const Icon(Icons.feedback, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FeedbackPage(role: 'asha')),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Manage Users'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
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
      onPressed: _isButtonLoading
          ? null // Disable button when loading
          : () async {
              setState(() => _isButtonLoading = true);

              if (label == "Manage Users") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ManageUsersPage(userEmail: widget.userEmail),
                  ),
                );
              }
              if (label == "Calendar") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CalendarPage(userEmail: widget.userEmail),
                  ),
                );
              }
              if (label == "Pregnant Women") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PregnantWomenPage(ashaEmail: widget.userEmail),
                  ),
                );
              }
              if (label == "Profile") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AshaProfilePage(userEmail: widget.userEmail),
                  ),
                );
              }

              setState(() => _isButtonLoading = false);
            },
      child: _isButtonLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Column(
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
