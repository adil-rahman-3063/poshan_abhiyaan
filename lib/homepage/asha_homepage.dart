import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../asha/manage_user.dart';
import '../asha/calendar.dart'; // ✅ Corrected import path

class ASHAHomePage extends StatefulWidget {
  final String userEmail;
  const ASHAHomePage({super.key, required this.userEmail});

  @override
  _ASHAHomePageState createState() => _ASHAHomePageState();
}

class _ASHAHomePageState extends State<ASHAHomePage> {
  int _selectedIndex = 0;

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
              // TODO: Open Notifications Page
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
          // Recent Notifications Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent Notifications",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 120, // Adjustable height
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("No new notifications"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Buttons Grid (2x2)
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 40),
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
          ),
          const SizedBox(height: 20),
        ],
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
                  ManageUsersPage(userEmail: widget.userEmail), // ✅ Pass email
            ),
          );
        }
        if (label == "Calendar") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CalendarPage(userEmail: widget.userEmail), // ✅ Pass email
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
