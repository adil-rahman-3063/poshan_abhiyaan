import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../user/calendar.dart'; // ✅ Import User Calendar Page

class UserHomePage extends StatefulWidget {
  final String userEmail;
  const UserHomePage({super.key, required this.userEmail});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0; // ✅ Mutable state

  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // ✅ Debugging calendar navigation
      print("📅 Navigating to Calendar with Email: ${widget.userEmail}");
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                UserCalendarPage(userEmail: widget.userEmail)),
      );
    } else if (index == 1) {
      // TODO: Navigate to Profile Page
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
              // TODO: Open Notifications Screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Greeting Message
          Text(
            getGreeting(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Current Date
          Text(
            currentDate,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Upcoming Events
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📅 Upcoming Events:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Nutrition Awareness - March 20, 2025", // TODO: Fetch dynamic events
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Community Health Check - March 25, 2025",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 2x2 Button Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 20.0,
              childAspectRatio: 1.2,
              children: [
                _buildHomeButton(Icons.person, "Profile", () {
                  // TODO: Navigate to Profile Page
                }),
                _buildHomeButton(Icons.calendar_today, "Calendar", () {
                  // ✅ Debugging calendar navigation
                  print(
                      "📅 Calendar button clicked. Email: ${widget.userEmail}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UserCalendarPage(userEmail: widget.userEmail)),
                  );
                }),
                _buildHomeButton(Icons.chat, "Chat", () {
                  // TODO: Navigate to Chat Page
                }),
                _buildHomeButton(Icons.info, "About", () {
                  // TODO: Navigate to About Page
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.brown,
            unselectedItemColor: Colors.black,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: 'Calendar'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for buttons in grid
  Widget _buildHomeButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () {
        print("🔘 Button Clicked: $label");
        onPressed();
      }, // ✅ Each button has its own navigation logic
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
