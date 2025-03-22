import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/google_sheets_service.dart';
import 'package:intl/intl.dart'; // Import intl for formatting dates

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
  bool isLoading = true; // ✅ Loading state

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
    setState(() => isLoading = true);

    List<Map<String, dynamic>> allEvents = await _sheetsService.fetchEvents();

    setState(() {
      events = allEvents
          .where((event) => event['block_number'] == blockNumber)
          .map((event) => {
                'event_name': event['event_name'].toString(),
                'description': event['description'].toString(),
                'date': event['date'].toString(),
                'block_number': event['block_number'].toString(),
              }) // ✅ Now correctly handling dynamic values
          .toList();

      isLoading = false;
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

    String date =
        "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";

    print("🟡 Debug: Block Number -> $blockNumber, Date -> $date");

    bool success = await _sheetsService.addEvent(
        eventName, description, date, blockNumber);

    if (success) {
      _eventNameController.clear();
      _eventDescriptionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event added successfully!")),
      );

      print("✅ Event Added Successfully!");

      // ✅ Refresh the event list
      _fetchEvents();
    } else {
      print("❌ Failed to add event.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to add event.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SingleChildScrollView(
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

            // 📜 Show Events List in a Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Container(
                height: 300, // ✅ Fixed height to make it scrollable
                decoration: BoxDecoration(
                  color: Colors.white, // ✅ Background color
                  borderRadius: BorderRadius.circular(10), // ✅ Rounded corners
                  border: Border.all(color: Colors.grey.shade300), // ✅ Border
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(), // ✅ Loading UI
                        )
                      : events.isEmpty
                          ? const Center(child: Text("No events found."))
                          : ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                var event = events[index];
                                return Card(
                                  elevation: 3,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      event['event_name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      "📅 ${DateFormat('yyyy-MM-dd').format(DateTime.parse(event['date'].toString()))}\n📝 ${event['description']}",
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
