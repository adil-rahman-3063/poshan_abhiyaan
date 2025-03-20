import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/google_sheets_service.dart'; // ✅ Import Google Sheets Service

class UserCalendarPage extends StatefulWidget {
  final String userEmail;
  const UserCalendarPage({super.key, required this.userEmail});

  @override
  _UserCalendarPageState createState() => _UserCalendarPageState();
}

class _UserCalendarPageState extends State<UserCalendarPage> {
  late CalendarFormat _calendarFormat;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, String>>> _events = {}; // ✅ Store events
  List<Map<String, String>> _selectedEvents = []; // ✅ Events for selected day
  String? _blockNumber; // ✅ User's block number
  bool _isLoading = true; // ✅ Show loading when page opens

  final GoogleSheetsService _googleSheetsService =
      GoogleSheetsService(); // ✅ Instance

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _fetchUserBlockNumber();
  }

  // ✅ Fetch User's Block Number First
  Future<void> _fetchUserBlockNumber() async {
    String? block =
        await _googleSheetsService.getUserBlockNumber(widget.userEmail);

    if (block != null) {
      setState(() {
        _blockNumber = block;
      });
      print("✅ Block Number Found: $_blockNumber");
      _fetchEvents(); // ✅ Fetch events after getting block number
    } else {
      print("❌ No block number found for user.");
      setState(() {
        _isLoading = false; // Stop loading if no block found
      });
    }
  }

  Future<void> _fetchEvents() async {
    if (_blockNumber == null) return;

    print("📅 Fetching events for Block $_blockNumber");

    List<Map<String, dynamic>> eventsData =
        await _googleSheetsService.getEventsByBlock(_blockNumber!);
    Map<DateTime, List<Map<String, String>>> eventsMap = {};

    for (var event in eventsData) {
      try {
        DateTime eventDate;
        String dateString = event['date']!.toString();

        if (RegExp(r'^\d+$').hasMatch(dateString)) {
          int serialNumber = int.parse(dateString);
          eventDate = DateTime(1899, 12, 30).add(Duration(days: serialNumber));
        } else {
          try {
            eventDate = DateFormat('yyyy-MM-dd').parse(dateString);
          } catch (e) {
            eventDate = DateFormat('dd/MM/yyyy').parse(dateString);
          }
        }

        eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (!eventsMap.containsKey(eventDate)) {
          eventsMap[eventDate] = [];
        }
        eventsMap[eventDate]!.add({
          'event_name': event['event_name'] ?? "Unknown Event",
          'description': event['description'] ?? "No Description",
        });

        print("📅 ✅ Event Added: ${event['event_name']} on $eventDate");
      } catch (e) {
        print(
            "❌ Error Parsing Date: ${event['event_name']} - ${event['date']} - $e");
      }
    }

    setState(() {
      _events = eventsMap;
      _isLoading = false; // ✅ Set loading to false after fetching events

      DateTime today = DateTime.now();
      DateTime normalizedToday = DateTime(today.year, today.month, today.day);

      _selectedEvents = _events[_selectedDay] ?? [];

      if (_selectedEvents.isEmpty && _events.containsKey(normalizedToday)) {
        _selectedDay = normalizedToday;
        _selectedEvents = _events[_selectedDay]!;
      }
    });

    print("✅ Final Events Map:");
    _events.forEach((key, value) {
      print("📅 $key -> ${value.map((e) => e['event_name']).toList()}");
    });
    print("🎯 Updated Selected Events: $_selectedEvents");
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    DateTime normalizedDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    print("📅 Selected: $normalizedDay | Focused: $focusedDay");

    setState(() {
      _selectedDay = normalizedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _events[normalizedDay] ?? [];
    });

    print("🎯 Events for Selected Day: $_selectedEvents");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Calendar")),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // ✅ Show loading on first open
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime(2024, 1, 1),
                  lastDay: DateTime(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  eventLoader: (day) {
                    DateTime normalizedDay =
                        DateTime(day.year, day.month, day.day);
                    return _events[normalizedDay] ?? [];
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color:
                          Colors.orange, // ✅ Event markers should be distinct
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Display Event List Below Calendar
                Expanded(child: _buildEventList()),
              ],
            ),
    );
  }

  // ✅ Widget to display events for the selected day
  Widget _buildEventList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(), // ✅ Show loading indicator
      );
    }

    if (_selectedEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No Events",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        var event = _selectedEvents[index];
        return ListTile(
          title: Text(
            event['event_name']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            event['description']!,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: const Icon(Icons.event, color: Colors.blue),
        );
      },
    );
  }
}
