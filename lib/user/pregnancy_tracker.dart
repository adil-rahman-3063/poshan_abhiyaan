import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/google_sheets_service.dart';

class PregnancyTrackerPage extends StatefulWidget {
  final String userEmail;

  const PregnancyTrackerPage({super.key, required this.userEmail});

  @override
  _PregnancyTrackerPageState createState() => _PregnancyTrackerPageState();
}

class _PregnancyTrackerPageState extends State<PregnancyTrackerPage> {
  int? weeksPregnant;
  DateTime? expectedDueDate;
  DateTime? ninthMonthDate;
  late CalendarFormat _calendarFormat;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _reminders = {}; // ✅ Store reminders by date

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _checkPregnancyData();
    _fetchReminders(); // ✅ Fetch reminders
  }

  // ✅ Fetch reminders from Google Sheets
  Future<void> _fetchReminders() async {
    try {
      print("⏳ Fetching reminders...");
      List<Map<String, String>> fetchedReminders =
          await GoogleSheetsService().getReminders(widget.userEmail);

      Map<DateTime, List<String>> remindersMap = {};

      for (var reminder in fetchedReminders) {
        String? reminderText = reminder['reminder'];
        String? dateString = reminder['date'];

        if (dateString != null &&
            reminderText != null &&
            dateString.isNotEmpty) {
          try {
            DateTime reminderDate = DateTime.parse(dateString);

            // ✅ Ensure only valid dates are processed
            DateTime formattedDate = DateTime(
                reminderDate.year, reminderDate.month, reminderDate.day);

            remindersMap.putIfAbsent(formattedDate, () => []);
            remindersMap[formattedDate]!.add(reminderText);
          } catch (e) {
            print("❌ Error parsing date: $dateString");
          }
        }
      }

      print("✅ Reminders Map: $remindersMap");
      setState(() {
        _reminders = remindersMap;
      });
    } catch (e) {
      print("❌ Error in _fetchReminders: $e");
    }
  }

  // ✅ Check if pregnancy data exists
  Future<void> _checkPregnancyData() async {
    Map<String, dynamic>? pregnancyData =
        await GoogleSheetsService().getPregnancyData(widget.userEmail);

    if (pregnancyData == null) {
      _askWeeksPregnant(); // Show popup if no data exists
    } else {
      setState(() {
        weeksPregnant = int.tryParse(pregnancyData['weeks_pregnant'] ?? '0');
        expectedDueDate =
            DateTime.tryParse(pregnancyData['expected_due_date'] ?? '');
        if (expectedDueDate != null) {
          ninthMonthDate = expectedDueDate!
              .subtract(const Duration(days: 28)); // 4 weeks before due date
        }
      });
    }
  }

  // ✅ Show popup to ask how far along they are
  void _askWeeksPregnant() {
    TextEditingController weeksController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (context) => AlertDialog(
        title: const Text("Pregnancy Tracker"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How many weeks pregnant are you?"),
            TextField(
              controller: weeksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Weeks"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              int? enteredWeeks = int.tryParse(weeksController.text);
              if (enteredWeeks != null && enteredWeeks > 0) {
                _savePregnancyData(enteredWeeks);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ✅ Save data to Google Sheets
  Future<void> _savePregnancyData(int weeksPregnant) async {
    setState(() {
      this.weeksPregnant = weeksPregnant;
      expectedDueDate =
          DateTime.now().add(Duration(days: (40 - weeksPregnant) * 7));
      ninthMonthDate = expectedDueDate!
          .subtract(const Duration(days: 28)); // 4 weeks before due date
    });

    // ✅ Fetch block number before saving
    String? blockNumber =
        await GoogleSheetsService().getUserBlockNumber(widget.userEmail);

    if (blockNumber == null) {
      print("❌ Error: Block number not found for ${widget.userEmail}");
      return;
    }

    await GoogleSheetsService().savePregnancyData(
      userEmail: widget.userEmail,
      weeksPregnant: weeksPregnant,
      expectedDueDate: DateFormat('yyyy-MM-dd').format(expectedDueDate!),
      blockNumber: blockNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pregnancy Tracker")),
      body: Column(
        children: [
          if (weeksPregnant != null && expectedDueDate != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "You're $weeksPregnant weeks pregnant.\n"
                "Expected Due Date: ${DateFormat('MMMM d, yyyy').format(expectedDueDate!)}\n"
                "Your 9th month starts: ${DateFormat('MMMM d, yyyy').format(ninthMonthDate!)}",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],

          // ✅ Calendar Display
          TableCalendar(
            focusedDay: DateTime.now(),
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              return _reminders[DateTime(day.year, day.month, day.day)] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),

          const SizedBox(height: 20),

          // ✅ Show reminders for the selected day BELOW the calendar
          Expanded(
            child: _selectedDay != null &&
                    _reminders.containsKey(DateTime(_selectedDay!.year,
                        _selectedDay!.month, _selectedDay!.day))
                ? ListView.builder(
                    itemCount: _reminders[DateTime(_selectedDay!.year,
                            _selectedDay!.month, _selectedDay!.day)]!
                        .length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading:
                              const Icon(Icons.event_note, color: Colors.green),
                          title: Text(
                            _reminders[DateTime(
                                _selectedDay!.year,
                                _selectedDay!.month,
                                _selectedDay!.day)]![index],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text("No reminders for today.")),
          ),
        ],
      ),
    );
  }
}
