import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';

class FeedbackPage extends StatefulWidget {
  final String role;

  const FeedbackPage({super.key, required this.role});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks(); // Call _fetchFeedbacks in initState
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      _feedbacks = await GoogleSheetsService().fetchFeedbacks();
      print("Fetched feedbacks: $_feedbacks");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching feedbacks: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFeedback(int index) async {
    try {
      int rowIndex = _feedbacks[index]['rowIndex'];
      bool success = await GoogleSheetsService().deleteFeedback(rowIndex);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback deleted successfully!")),
        );
        _fetchFeedbacks(); // Refresh the list after deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting feedback.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting feedback: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feedback & Suggestions")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _feedbacks.isEmpty
                      ? const Center(child: Text("No feedbacks yet."))
                      : ListView.builder(
                          itemCount: _feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedbacks[index];
                            return ListTile(
                              title: Text(feedback['feedback']),
                              subtitle:
                                  Text('Submitted by: ${feedback['role']}'),
                              trailing: widget.role == 'admin'
                                  ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteFeedback(index),
                                    )
                                  : null,
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
