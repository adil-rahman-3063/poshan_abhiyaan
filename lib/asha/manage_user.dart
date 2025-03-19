import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart'; // ✅ Correct import path

class ManageUsersPage extends StatefulWidget {
  final String userEmail;
  const ManageUsersPage({super.key, required this.userEmail});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  Map<String, dynamic> currentUser = {};
  Map<String, List<Map<String, dynamic>>> usersByBlock = {};
  Map<String, Map<String, TextEditingController>> controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchUserAndUsers();
  }

  Future<void> _fetchUserAndUsers() async {
    print("⏳ Fetching user role and users...");

    await _sheetsService.init();

    try {
      final workers = await _sheetsService.fetchAshaWorkers();
      final users = await _sheetsService.fetchAshaUsers(widget.userEmail);
      final admins = await _sheetsService.fetchAdmins();

      print("✅ Fetched ${workers.length} ASHA Workers");
      print("✅ Fetched ${users.length} Users");
      print("✅ Fetched ${admins.length} Admins");

      Map<String, dynamic> fetchedUser = await _getCurrentUser(workers, admins);
      if (fetchedUser.isEmpty) {
        print("❌ Error: User not found!");
        return;
      }

      setState(() {
        currentUser = fetchedUser;
        usersByBlock.clear();
        controllers.clear();

        for (var user in users) {
          String block = user['block_number'];

          if (currentUser['role'] == 'asha_worker' &&
              block != currentUser['block_number']) {
            continue;
          }

          usersByBlock.putIfAbsent(block, () => []).add(user);

          controllers[user['email']] = {
            'name': TextEditingController(text: user['name'] ?? ''),
            'phone': TextEditingController(text: user['phone'] ?? ''),
            'age': TextEditingController(text: user['age'] ?? ''),
            'category': TextEditingController(text: user['category'] ?? ''),
          };
        }
      });

      print("🔄 State Updated Successfully!");
    } catch (e) {
      print("❌ Error Fetching Data: $e");
    }
  }

  Future<Map<String, dynamic>> _getCurrentUser(
      List<Map<String, dynamic>> workers,
      List<Map<String, dynamic>> admins) async {
    for (var admin in admins) {
      if (admin['email'] == widget.userEmail) {
        return {'role': 'admin'};
      }
    }

    for (var worker in workers) {
      if (worker['email'] == widget.userEmail ||
          worker['username'] == widget.userEmail) {
        return {
          'role': 'asha_worker',
          'email': worker['email'],
          'block_number': worker['block_number'],
        };
      }
    }

    return {};
  }

  Future<void> _updateUserField(String email, String field) async {
    String newValue = controllers[email]?[field]?.text ?? '';
    bool success = await _sheetsService.updateUserField(email, field, newValue);
    if (success) {
      print("✅ Updated $field for $email");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $field updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update $field.")),
      );
    }
  }

  Future<void> _deleteUser(String email) async {
    int? rowIndex = await _sheetsService.getUserRowIndexByEmail(email);
    if (rowIndex != null) {
      bool deleted = await _sheetsService.deleteUser(rowIndex, 'asha_user');
      if (deleted) {
        setState(() {
          usersByBlock.forEach((block, users) {
            users.removeWhere((user) => user['email'] == email);
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ User deleted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to delete user.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: usersByBlock.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: usersByBlock.entries.map((entry) {
                String block = entry.key;
                List<Map<String, dynamic>> users = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Block: $block",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...users.map((user) {
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              _buildEditableRow(user['email'], 'name', 'Name'),
                              const SizedBox(height: 8),
                              _buildEditableRow(
                                  user['email'], 'phone', 'Phone'),
                              const SizedBox(height: 8),
                              _buildEditableRow(user['email'], 'age', 'Age'),
                              const SizedBox(height: 8),
                              _buildDropdownRow(user['email'],
                                  'category'), // ✅ Dropdown for Category
                              const SizedBox(height: 8),
                              if (currentUser['role'] == 'asha_worker') ...[
                                ElevatedButton(
                                  onPressed: () => _deleteUser(user['email']),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text("Delete User",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEditableRow(String email, String field, String label) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controllers[email]?[field],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Edit $label',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _updateUserField(email, field),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(String email, String field) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: (controllers[email]?.containsKey(field) == true &&
                    (controllers[email]![field]!.text ?? '').isNotEmpty)
                ? controllers[email]![field]!.text
                : 'Choose Later', // ✅ Default value if null or empty
            items: ['Under 15', 'Pregnancy', 'Choose Later'].map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  controllers[email]?[field]?.text = newValue;
                });
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Category',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green), // ✅ Tick icon
          onPressed: () => _updateUserField(email, field),
        ),
      ],
    );
  }
}
