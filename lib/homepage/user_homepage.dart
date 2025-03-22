import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../user/calendar.dart';
import '../user/profile.dart';
import '../services/google_sheets_service.dart';
import '../user/pregnancy_tracker.dart';
import '../user/notification.dart';
import '../user/about.dart';
import '../user/chat.dart';
import '../user/feedback.dart';

class UserHomePage extends StatefulWidget {
  final String userEmail;
  const UserHomePage({super.key, required this.userEmail});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _userCategory = ''; // Added to store user category

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchUserCategory(); // Fetch user category on init
  }

  Future<void> _fetchUserCategory() async {
    try {
      String? category =
          await GoogleSheetsService().getUserCategory(widget.userEmail);
      setState(() {
        _userCategory = category ?? '';
      });
    } catch (e) {
      print("❌ Error fetching user category: $e");
    }
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);

    String? blockNumber =
        await GoogleSheetsService().getUserBlockNumber(widget.userEmail);
    if (blockNumber == null) return;

    List<Map<String, dynamic>> allEvents =
        await GoogleSheetsService().getEventsByBlock(blockNumber);

    List<Map<String, dynamic>> processedEvents = [];
    DateTime today = DateTime.now();

    for (var event in allEvents) {
      try {
        String eventName = event['event_name']?.toString() ?? "Unknown Event";
        String description =
            event['description']?.toString() ?? "No description";
        String rawDate = event['date']?.toString() ?? "";
        DateTime? parsedDate;

        if (rawDate.isNotEmpty) {
          if (RegExp(r'^\d+$').hasMatch(rawDate)) {
            parsedDate =
                DateTime(1899, 12, 30).add(Duration(days: int.parse(rawDate)));
          } else if (rawDate.contains("/")) {
            parsedDate = DateFormat("dd/MM/yyyy").parse(rawDate);
          } else if (rawDate.contains("-")) {
            parsedDate = DateTime.tryParse(rawDate);
          }
        }

        if (parsedDate == null)
          throw FormatException("Invalid date format: $rawDate");

        if (parsedDate.isAfter(today) || parsedDate.isAtSameMomentAs(today)) {
          processedEvents.add({
            'event_name': eventName,
            'description': description,
            'date': DateFormat('MMMM d, yyyy').format(parsedDate),
            'block_number': blockNumber,
          });
        }
      } catch (e) {
        print("❌ Error processing event: $e");
      }
    }

    processedEvents.sort((a, b) {
      DateTime dateA = DateFormat('MMMM d, yyyy').parse(a['date']);
      DateTime dateB = DateFormat('MMMM d, yyyy').parse(b['date']);
      return dateA.compareTo(dateB);
    });

    setState(() {
      _events = processedEvents.take(2).toList();
      _isLoading = false;
    });

    print("✅ Upcoming Events: $_events");
  }

  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    if (hour >= 17 && hour < 21) return "Good Evening";
    return "Good Night";
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                UserCalendarPage(userEmail: widget.userEmail)),
      );
    } else if (index == 1) {
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => UserProfilePage(userEmail: widget.userEmail)),
      );
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Access Denied"),
          content: const Text(
              "You do not have permission to access the Pregnancy Tracker."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                        UserNotificationsPage(userEmail: widget.userEmail)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            getGreeting(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            currentDate,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
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
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _events.isEmpty
                        ? const Text("No upcoming events",
                            style: TextStyle(fontSize: 16))
                        : Column(
                            children: _events
                                .map((event) => Text(
                                      "${event['event_name']} - ${event['date']}",
                                      style: const TextStyle(fontSize: 16),
                                    ))
                                .toList(),
                          ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 20.0,
              childAspectRatio: 1.2,
              children: [
                _buildHomeButton(Icons.person, "Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UserProfilePage(userEmail: widget.userEmail)),
                  );
                }),
                _buildHomeButton(Icons.calendar_today, "Calendar", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UserCalendarPage(userEmail: widget.userEmail)),
                  );
                }),
                _buildHomeButton(Icons.chat, "Chat", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HealthChatPage()),
                  );
                }),
                _buildHomeButton(Icons.info, "About", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutPage()),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: _buildHomeButton(Icons.pregnant_woman, "Pregnancy Tracker",
                  () {
                if (_userCategory == "Pregnancy") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PregnancyTrackerPage(userEmail: widget.userEmail)),
                  );
                } else {
                  _showAccessDeniedDialog();
                }
              }),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown[400],
        child: const Icon(Icons.feedback, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FeedbackPage(role: 'user')),
          );
        },
      ),
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
                  icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: Colors.white),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}
