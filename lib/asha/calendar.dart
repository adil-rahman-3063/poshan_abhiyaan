import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/google_sheets_service.dart';

class CalendarPage extends StatefulWidget {
  final String userEmail;
  const CalendarPage({super.key, required this.userEmail});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String blockNumber = ''; // Will store the ASHA worker's block number
  List<Map<String, dynamic>> events = []; // Stores events from Sheets

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAshaWorkerBlock();
  }

  Future<void> _fetchAshaWorkerBlock() async {
    await _sheetsService.init();

    // 🔍 Convert username to email
    String? userEmail =
        await _sheetsService.getEmailByUsername(widget.userEmail);
    if (userEmail == null) {
      print("❌ Error: Email Not Found for Username ${widget.userEmail}");
      return;
    }

    print("✅ Mapped Username ${widget.userEmail} to Email $userEmail");

    List<Map<String, dynamic>> workers =
        await _sheetsService.fetchAshaWorkers();

    print("📝 All ASHA Worker Emails in Sheets:");
    for (var worker in workers) {
      print("📌 ${worker['email']} -> Block: ${worker['block_number']}");
    }

    String? fetchedBlockNumber =
        await _sheetsService.getAshaWorkerBlockNumber(userEmail);

    if (fetchedBlockNumber != null) {
      setState(() {
        blockNumber = fetchedBlockNumber;
      });
      _fetchEvents();
    } else {
      print("❌ ASHA Worker Not Found for Email: $userEmail");
    }
  }

  Future<void> _fetchEvents() async {
    List<Map<String, dynamic>> allEvents = await _sheetsService.fetchEvents();

    setState(() {
      events = allEvents
          .where((event) => event['block_number'] == blockNumber)
          .toList();
    });

    print("✅ Fetched ${events.length} events for block $blockNumber");
  }

  Future<void> _addEvent() async {
    String eventName = _eventNameController.text.trim();
    String description = _eventDescriptionController.text.trim();

    if (eventName.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Event name and description cannot be empty.")),
      );
      return;
    }

    // ✅ Convert _selectedDay (DateTime) to String (YYYY-MM-DD)
    String date =
        "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";

    print("🟡 Debug: Block Number -> $blockNumber, Date -> $date");

    bool success = await _sheetsService.addEvent(
        eventName, description, date, blockNumber);

    if (success) {
      setState(() {
        events.add({
          'event_name': eventName,
          'description': description,
          'date': date,
          'block_number': blockNumber,
        });
      });

      _eventNameController.clear();
      _eventDescriptionController.clear();
      print("✅ Event Added Successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event added successfully!")),
      );
    } else {
      print("❌ Failed to add event.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SingleChildScrollView(
        // ✅ Fix overflow issue
        child: Column(
          children: [
            // 📅 Calendar Widget
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),

            // 📌 Add Event Form
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  TextField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Event Name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eventDescriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addEvent,
                    child: const Text("Add Event"),
                  ),
                ],
              ),
            ),

            // 📜 Show Events List
            SizedBox(
              height: 300, // ✅ Ensures scrollable space
              child: events.isEmpty
                  ? const Center(child: Text("No events found."))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        var event = events[index];
                        return ListTile(
                          title: Text(event['event_name']),
                          subtitle: Text(
                              "📅 ${event['date']}\n📝 ${event['description']}"),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
