import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/google_sheets_service.dart';

class PregnantWomenPage extends StatefulWidget {
  final String ashaEmail;

  const PregnantWomenPage({super.key, required this.ashaEmail});

  @override
  _PregnantWomenPageState createState() => _PregnantWomenPageState();
}

class _PregnantWomenPageState extends State<PregnantWomenPage> {
  List<Map<String, String>> pregnantWomen = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
  }

  // ✅ Fetch pregnant women for the ASHA worker's block
  Future<void> _loadPregnantWomen() async {
    setState(() => isLoading = true);

    String? blockNumber =
        await GoogleSheetsService().getAshaBlockNumber(widget.ashaEmail);

    if (blockNumber == null) {
      print("❌ Error: ASHA worker block number not found!");
      setState(() => isLoading = false);
      return;
    }

    List<Map<String, String>> women =
        await GoogleSheetsService().getPregnantWomenByBlock(blockNumber);

    setState(() {
      pregnantWomen = women;
      isLoading = false;
    });
  }

  // ✅ Open detailed pregnancy tracking page
  void _openPregnancyDetails(Map<String, String> woman) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PregnancyDetailsPage(pregnantWoman: woman),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pregnant Women in Your Block")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pregnantWomen.isEmpty
              ? const Center(
                  child: Text("No pregnant women found in your block."),
                )
              : ListView.builder(
                  itemCount: pregnantWomen.length,
                  itemBuilder: (context, index) {
                    final woman = pregnantWomen[index];
                    return Card(
                      child: ListTile(
                        title: Text(woman['email'] ?? "Unknown"),
                        subtitle: Text(
                            "Weeks Pregnant: ${woman['weeks_pregnant']} | Due: ${woman['expected_due_date']}"),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _openPregnancyDetails(woman),
                      ),
                    );
                  },
                ),
    );
  }
}

// ✅ Pregnancy Details Page for ASHA Workers
class PregnancyDetailsPage extends StatefulWidget {
  final Map<String, String> pregnantWoman;

  const PregnancyDetailsPage({super.key, required this.pregnantWoman});

  @override
  _PregnancyDetailsPageState createState() => _PregnancyDetailsPageState();
}

class _PregnancyDetailsPageState extends State<PregnancyDetailsPage> {
  List<Map<String, String>> reminders = [];
  bool isLoading = true; // ✅ Loading state

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // ✅ Load existing reminders for this woman
  Future<void> _loadReminders() async {
    setState(() => isLoading = true);

    String email = widget.pregnantWoman['email']!;
    print("✅ Fetching reminders for email: $email");

    List<Map<String, String>> existingReminders =
        await GoogleSheetsService().getRemindersForPregnantWoman(email);

    print("✅ Fetched Reminders: $existingReminders");

    setState(() {
      reminders = existingReminders;
      isLoading = false;
    });
  }

  // ✅ Add new reminder
  void _addReminder() {
    TextEditingController reminderController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    bool isSaving = false; // ✅ Loading state for saving

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Reminder"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reminderController,
                  decoration:
                      const InputDecoration(labelText: "Enter Reminder"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: "Select Date",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      setDialogState(() => dateController.text = formattedDate);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        String newReminder = reminderController.text.trim();
                        String selectedDate = dateController.text.trim();

                        if (newReminder.isNotEmpty && selectedDate.isNotEmpty) {
                          setDialogState(() => isSaving = true);

                          await GoogleSheetsService().addReminder(
                            email: widget.pregnantWoman['email']!,
                            reminder: newReminder,
                            date: selectedDate,
                          );

                          Navigator.pop(context);
                          _loadReminders();
                        }
                      },
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tracking: ${widget.pregnantWoman['email']}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weeks Pregnant: ${widget.pregnantWoman['weeks_pregnant']}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Expected Due Date: ${widget.pregnantWoman['expected_due_date']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Reminders:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator()) // ✅ Show loading while fetching reminders
                        : reminders.isEmpty
                            ? const Center(
                                child: Text("No reminders added yet."))
                            : ListView.builder(
                                itemCount: reminders.length,
                                itemBuilder: (context, index) {
                                  final reminder = reminders[index];

                                  return Card(
                                    child: ListTile(
                                      title: Text(reminder['reminder'] ?? ""),
                                      subtitle: Text(
                                          "Date: ${reminder['date'] ?? "No date"}"),
                                      leading: const Icon(Icons.notifications),
                                    ),
                                  );
                                },
                              ),
                  )
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}
