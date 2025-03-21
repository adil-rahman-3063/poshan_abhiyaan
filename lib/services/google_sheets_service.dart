import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:flutter/services.dart';
import '../homepage/user_homepage.dart';
import '../homepage/asha_homepage.dart';

const _credentials =
    'assets/service_account.json'; // Google Sheets API credentials
const _spreadsheetId = '1v_G04Plro5XMZL9XYfoH_KS5gF6ntlb7ovw8Z4tWjHA';

class GoogleSheetsService {
  late final GSheets _gsheets;
  late final Spreadsheet _spreadsheet;
  Worksheet? _usersSheet;
  Worksheet? _ashaWorkersSheet;
  Worksheet? _eventsSheet; // ✅ Declare events sheet
  Worksheet? _adminNotificationSheet; // ✅ Declare admin notification sheet
  Worksheet? _ashaNotificationSheet; // ✅ Declare ASHA notification sheet

  bool _isInitialized = false;

  GoogleSheetsService();

  /// ✅ Initialize Google Sheets Service
  /// ✅ Initialize Google Sheets Service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print("⏳ Initializing Google Sheets...");
      final credentials = await rootBundle.loadString(_credentials);
      _gsheets = GSheets(credentials);
      _spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);

      _usersSheet = await _getOrCreateSheet('asha_user');
      _ashaWorkersSheet = await _getOrCreateSheet('asha_workers');
      _eventsSheet = await _getOrCreateSheet('events');
      // ✅ Initialize events sheet
      _adminNotificationSheet = await _getOrCreateSheet('admin_notifications');

      _ashaNotificationSheet = await _getOrCreateSheet('asha_notifications');

      _isInitialized = true;
      print("✅ Google Sheets Initialized Successfully");
    } catch (e) {
      print("❌ Error Initializing Google Sheets: $e");
    }

    if (_ashaWorkersSheet == null) {
      print("❌ ASHA Workers Sheet Not Found!");
    } else {
      print("✅ ASHA Workers Sheet Loaded Successfully.");
    }
  }

  /// ✅ Convert Google Sheets Date to DateTime
  DateTime convertGoogleSheetsDate(dynamic dateValue) {
    if (dateValue is num) {
      // Google Sheets stores dates as days since 1899-12-30
      return DateTime(1899, 12, 30).add(Duration(days: dateValue.toInt()));
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue); // Parse if it's a proper date string
      } catch (e) {
        print("❌ Error Parsing Date String: $dateValue - $e");
        return DateTime.now(); // Default fallback
      }
    }
    return DateTime.now(); // Fallback for unexpected formats
  }

  /// ✅ Ensure a worksheet exists, create if missing
  Future<Worksheet?> _getOrCreateSheet(String title) async {
    var sheet = _spreadsheet.worksheetByTitle(title);
    if (sheet == null) {
      print("⚠️ Sheet '$title' not found, creating...");
      sheet = await _spreadsheet.addWorksheet(title);
      if (sheet != null) {
        print("✅ Sheet '$title' created successfully.");
      } else {
        print("❌ Failed to create sheet '$title'.");
      }
    }
    return sheet;
  }

  /// 🔹 **Login function for ASHA Worker or User**
  Future<void> login(
      BuildContext context, String identifier, String password) async {
    await init();

    final bool isWorker = await _authenticateWorker(identifier, password);
    if (isWorker) {
      print("✅ ASHA Worker Logged In: $identifier");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ASHAHomePage(userEmail: identifier),
        ),
      );
      return;
    }

    final bool isUser = await _authenticateUser(identifier, password);
    if (isUser) {
      print("✅ User Logged In: $identifier");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => UserHomePage(userEmail: identifier)),
      );
      return;
    }

    print("❌ Login Failed: Invalid credentials");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid email/username or password')),
    );
  }

  /// ✅ **Authenticate ASHA Worker**
  Future<bool> _authenticateWorker(String identifier, String password) async {
    if (_ashaWorkersSheet == null) {
      print('❌ ASHA Workers Sheet Not Found!');
      return false;
    }

    final allRows = await _ashaWorkersSheet!.values.allRows();
    for (var row in allRows) {
      if (row.length >= 8 &&
          (row[6] == identifier || row[4] == identifier) &&
          row[7] == password) {
        return true;
      }
    }
    return false;
  }

  /// ✅ **Authenticate ASHA User**
  Future<bool> _authenticateUser(String identifier, String password) async {
    if (_usersSheet == null) {
      print('❌ Users Sheet Not Found!');
      return false;
    }

    final allRows = await _usersSheet!.values.allRows();
    for (var row in allRows) {
      if (row.length >= 8 &&
          (row[1] == identifier || row[2] == identifier) &&
          row[7] == password) {
        return true;
      }
    }
    return false;
  }

  /// 🔹 **Register a new ASHA worker**
  Future<void> insertAshaWorker({
    required String name,
    required String phone,
    required String blockNumber,
    required String email,
    required String idUrl,
    required String username,
    required String password,
  }) async {
    await init();

    if (_ashaWorkersSheet == null || _adminNotificationSheet == null) {
      print('❌ ASHA Workers or Admin Notifications Sheet Not Found!');
      return;
    }

    try {
      final allRows = await _ashaWorkersSheet!.values.allRows();
      int newId = allRows.isNotEmpty
          ? (int.tryParse(allRows.last[0] ?? '0') ?? 0) + 1
          : 1;

      await _ashaWorkersSheet!.values.appendRow([
        newId.toString(),
        name,
        phone,
        blockNumber,
        email,
        idUrl,
        username,
        password,
        "pending", // Column I - Verification status
      ]);

      print(
          '✅ ASHA Worker Registered: $name (ID: $newId) - Pending Verification');

      // ✅ Insert notification for admin
      await _adminNotificationSheet!.values.appendRow([
        "$name ($blockNumber) verification pending",
        DateTime.now().toIso8601String() // Column B - Timestamp
      ]);

      print(
          '✅ Notification Added for Admin: $name ($blockNumber) verification pending');
    } catch (e) {
      print('❌ Error Registering ASHA Worker: $e');
    }
  }

  /// 🔹 **Register a new ASHA user**
  Future<void> insertAshaUser({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String blockNumber,
    required String dob,
    String? category,
    required String password,
  }) async {
    await init();

    if (_usersSheet == null) {
      print("❌ ERROR: Users sheet not found!");
      return;
    }

    int age = _calculateAge(dob);

    await _usersSheet!.values.appendRow([
      name,
      phone,
      email,
      address,
      blockNumber,
      dob,
      category ?? '',
      password,
      age.toString(),
    ]);

    print("✅ User $name registered successfully!");
  }

  /// 🔹 **Calculate Age from Birthdate**
  int _calculateAge(String dob) {
    try {
      if (dob.length != 8) {
        print('❌ Invalid DOB Format: $dob (Expected: DDMMYYYY)');
        return 0;
      }

      int birthYear = int.parse(dob.substring(4, 8));
      int currentYear = DateTime.now().year;
      int age = currentYear - birthYear;

      print('✅ Age Calculated: $age years (DOB: $dob)');
      return age;
    } catch (e) {
      print('❌ Error Calculating Age for DOB: $dob | Error: $e');
      return 0;
    }
  }

  Future<bool> authenticateAdmin(
      {required String identifier, required String password}) async {
    await init(); // Ensure Google Sheets is initialized

    final adminSheet = await _getOrCreateSheet('admin');
    if (adminSheet == null) {
      print("❌ ERROR: Admin sheet not found!");
      return false;
    }

    try {
      print("⏳ Checking Admin Credentials...");

      final allRows = await adminSheet.values.allRows();
      for (var row in allRows) {
        if (row.length >= 3) {
          // Ensure the row has at least three columns (name, email, password)
          String adminEmail = row[1]; // Column B (Email)
          String adminPassword = row[2]; // Column C (Password)

          if (identifier == adminEmail && password == adminPassword) {
            print("✅ Admin Login Successful: $identifier");
            return true;
          }
        }
      }

      print("❌ Invalid Admin Credentials: $identifier");
      return false;
    } catch (e) {
      print("❌ Error in Admin Authentication: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAshaWorkers() async {
    if (_ashaWorkersSheet == null) {
      print("❌ Error: ASHA Workers Sheet Not Found!");
      return [];
    }

    try {
      final rows = await _ashaWorkersSheet!.values.map.allRows();
      if (rows == null || rows.isEmpty) {
        print("⚠️ Warning: No ASHA Worker Data Found!");
        return [];
      }

      return rows
          .map((row) => {
                'id': row['id'] ?? '',
                'name': row['name'] ?? 'Unknown',
                'phone': row['phone'] ?? 'N/A',
                'block_number': row['block_number'] ?? '',
                'email': row['email'] ?? '',
                'id_url': row['id_url'] ?? '',
                'username': row['username'] ?? '',
                'password': row['password'] ?? '',
                'verification':
                    row['verification'] ?? 'pending', // ✅ Added this line
              })
          .toList();
    } catch (e) {
      print("❌ Error Fetching ASHA Workers: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAshaUsers(String ashaEmail) async {
    if (_usersSheet == null || _ashaWorkersSheet == null) {
      print("❌ Error: Required Sheet Not Found!");
      return [];
    }

    try {
      // 🔍 Fetch ASHA worker details to get block number
      final ashaRows = await _ashaWorkersSheet!.values.map.allRows();
      print("📋 All ASHA Workers Data: $ashaRows"); // Debug ASHA workers

      final ashaWorker = ashaRows?.firstWhere(
        (row) => row['email'] == ashaEmail || row['username'] == ashaEmail,
        orElse: () => {},
      );

      if (ashaWorker == null || ashaWorker.isEmpty) {
        print("❌ Error: ASHA Worker Not Found for Email/Username: $ashaEmail");
        return [];
      }

      String ashaBlockNumber = ashaWorker['block_number'] ?? '';
      print("✅ ASHA Worker Block Number: $ashaBlockNumber");

      // 🔍 Fetch all users
      final userRows = await _usersSheet!.values.map.allRows();
      print("📋 All Users Data: $userRows"); // Debug all users

      if (userRows == null || userRows.isEmpty) {
        print("⚠️ Warning: No ASHA Users Data Found!");
        return [];
      }

      // Filter users by block number
      final filteredUsers = userRows.where((row) {
        return row['block_number'] == ashaBlockNumber;
      }).map((row) {
        return {
          'name': row['name'] ?? 'Unknown',
          'phone': row['phone'] ?? 'N/A',
          'email': row['email'] ?? '',
          'address': row['address'] ?? 'No Address',
          'block_number': row['block_number'] ?? '',
          'dob': row['dob'] ?? '',
          'category': row['category'] ?? '',
          'password': row['password'] ?? '',
          'age': row['age'] ?? 'N/A',
        };
      }).toList();

      print("📋 Filtered Users List (Block $ashaBlockNumber): $filteredUsers");
      return filteredUsers;
    } catch (e) {
      print("❌ Error Fetching ASHA Users: $e");
      return [];
    }
  }

  Future<bool> updateUserField(
      String email, String field, String newValue) async {
    if (_usersSheet == null) {
      print("❌ Error: Users Sheet Not Found!");
      return false;
    }

    try {
      final rows = await _usersSheet!.values.map.allRows();
      if (rows == null || rows.isEmpty) return false;

      // Define column mappings (adjust based on your sheet)
      final columnMapping = {
        'name': 1,
        'phone': 2,
        'email': 3,
        'address': 4,
        'block_number': 5,
        'dob': 6,
        'category': 7,
        'password': 8,
        'age': 9,
      };

      if (!columnMapping.containsKey(field)) {
        print("❌ Error: Invalid Field Name $field");
        return false;
      }

      int columnIndex = columnMapping[field]!;
      int? rowIndex = rows.indexWhere((row) => row['email'] == email);

      if (rowIndex != -1) {
        await _usersSheet!.values
            .insertValue(newValue, column: columnIndex, row: rowIndex + 2);
        print("✅ Successfully updated $field for $email");
        return true;
      }

      print("⚠️ User with email $email not found!");
      return false;
    } catch (e) {
      print("❌ Error Updating User Data: $e");
      return false;
    }
  }

  Future<bool> deleteUser(int rowIndex, String sheetName) async {
    await init();
    try {
      final sheet = sheetName == 'asha_user' ? _usersSheet : _ashaWorkersSheet;
      if (sheet == null) {
        print("❌ Error: Sheet $sheetName Not Found!");
        return false;
      }

      await sheet.deleteRow(rowIndex);
      print("✅ Successfully deleted row $rowIndex from $sheetName");
      return true;
    } catch (e) {
      print("❌ Error deleting user: $e");
      return false;
    }
  }

  Future<int?> getUserRowIndexByEmail(String email) async {
    await init();
    if (_usersSheet == null) {
      print("❌ Error: Users Sheet Not Found!");
      return null;
    }

    try {
      final rows = await _usersSheet!.values.allRows();
      for (int i = 1; i < rows.length; i++) {
        if (rows[i].length > 2 && rows[i][2] == email) {
          return i + 1; // Convert to 1-based index for Google Sheets
        }
      }
    } catch (e) {
      print("❌ Error finding user by email: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchAdmins() async {
    await init(); // Ensure Google Sheets API is initialized

    final adminSheet = await _getOrCreateSheet('admin');
    if (adminSheet == null) {
      print("❌ ERROR: Admin sheet not found!");
      return [];
    }

    try {
      final allRows = await adminSheet.values.allRows();
      if (allRows.isEmpty) {
        print("⚠️ No admin records found!");
        return [];
      }

      List<Map<String, dynamic>> admins = [];
      for (var row in allRows.skip(1)) {
        admins.add({
          'name': row.isNotEmpty ? row[0] : '', // Name in Column A
          'email': row.length > 1 ? row[1] : '', // Email in Column B
          'password': row.length > 2 ? row[2] : '', // Password in Column C
        });
      }

      print("✅ Admins fetched: ${admins.length}");
      return admins;
    } catch (e) {
      print("❌ Error fetching admins: $e");
      return [];
    }
  }

  Future<String?> getEmailByUsername(String usernameOrEmail) async {
    await init();
    final workers = await fetchAshaWorkers();
    final admins = await fetchAdmins();

    // ✅ If input is already an email, return it directly
    if (usernameOrEmail.contains('@') && usernameOrEmail.contains('.')) {
      print("✅ Input is already an email: $usernameOrEmail");
      return usernameOrEmail;
    }

    // 🔍 Search ASHA Workers by username
    for (var worker in workers) {
      if (worker['username'].trim().toLowerCase() ==
          usernameOrEmail.trim().toLowerCase()) {
        print("✅ ASHA Worker Found: $usernameOrEmail → ${worker['email']}");
        return worker['email'];
      }
    }

    // 🔍 Search Admins by username
    for (var admin in admins) {
      if (admin['username'].trim().toLowerCase() ==
          usernameOrEmail.trim().toLowerCase()) {
        print("✅ Admin Found: $usernameOrEmail → ${admin['email']}");
        return admin['email'];
      }
    }

    print("❌ No Email found for Username: $usernameOrEmail");
    return null; // ❌ Email not found
  }

  /// ✅ Fetch Events from Google Sheets
  Future<List<Map<String, dynamic>>> fetchEvents({String? blockNumber}) async {
    await init();

    if (_eventsSheet == null) {
      print("❌ Error: Events Sheet Not Found!");
      return [];
    }

    final rows = await _eventsSheet!.values.allRows();
    if (rows.isEmpty) {
      print("⚠️ No Events Found!");
      return [];
    }

    final filteredEvents = rows.where((row) {
      return row.length >= 4 && (blockNumber == null || row[3] == blockNumber);
    }).map((row) {
      return {
        'event_name': row.isNotEmpty ? row[0] ?? '' : '',
        'description': row.length > 1 ? row[1] ?? '' : '',
        'date': row.length > 2
            ? convertGoogleSheetsDate(row[2]).toIso8601String()
            : '',
        'block_number': row.length > 3 ? row[3] ?? '' : '',
      };
    }).toList();

    print(
        "📅 Retrieved ${filteredEvents.length} Events for Block: $blockNumber");
    return filteredEvents;
  }

  Future<bool> addEvent(String eventName, String description, String date,
      String blockNumber) async {
    await init(); // ✅ Ensure Google Sheets is initialized

    if (_eventsSheet == null) {
      print("❌ Error: Events Sheet Not Found!");
      return false;
    }

    // ✅ Append event to Google Sheets
    await _eventsSheet!.values.appendRow([
      eventName,
      description,
      date, // Keep date as String
      blockNumber
    ]);

    print("✅ Event Added Successfully!");
    return true;
  }

  Future<String?> getAshaWorkerBlockNumber(String email) async {
    await init(); // Ensure sheets are initialized
    List<Map<String, dynamic>> workers = await fetchAshaWorkers();

    for (var worker in workers) {
      print(
          "🔍 Checking Worker: ${worker['email']} -> ${worker['block_number']}"); // Debugging line
      if (worker['email'].trim().toLowerCase() == email.trim().toLowerCase()) {
        print(
            "✅ Found ASHA Worker: ${worker['email']} with Block: ${worker['block_number']}");
        return worker['block_number'];
      }
    }

    print("❌ No ASHA Worker found for email: $email");
    return null;
  }

  Future<String?> getUserBlockNumber(String email) async {
    await init(); // Ensure Google Sheets API is initialized

    if (_usersSheet == null) {
      print("❌ Error: Users Sheet Not Found!");
      return null;
    }

    try {
      // Fetch all user data from the 'asha_user' sheet
      final allRows = await _usersSheet!.values.map.allRows();
      if (allRows == null || allRows.isEmpty) {
        print("⚠️ Warning: No user data found in Google Sheets!");
        return null;
      }

      // Search for the user by email
      for (var row in allRows) {
        if (row['email'] == email) {
          print("✅ Found Block Number for $email: ${row['block_number']}");
          return row['block_number'];
        }
      }

      print("❌ No block number found for $email");
      return null;
    } catch (e) {
      print("❌ Error fetching block number: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByBlock(
      String blockNumber) async {
    await init();

    if (_eventsSheet == null) {
      print("❌ Error: Events Sheet Not Found!");
      return [];
    }

    try {
      final rows = await _eventsSheet!.values.allRows();
      if (rows.isEmpty) {
        print("⚠️ No Events Found!");
        return [];
      }

      // ✅ Filter events by block number
      final filteredEvents = rows.where((row) {
        return row.length >= 4 &&
            row[3] == blockNumber; // Column 4 (D) → Block Number
      }).map((row) {
        return {
          'event_name': row[0], // Column 1 (A) → Event Name
          'description': row[1], // Column 2 (B) → Description
          'date': row[2], // Column 3 (C) → Date
          'block_number': row[3], // Column 4 (D) → Block Number
        };
      }).toList();

      print(
          "✅ Events Fetched for Block $blockNumber: ${filteredEvents.length}");
      return filteredEvents;
    } catch (e) {
      print("❌ Error Fetching Events: $e");
      return [];
    }
  }

  Future<bool> updateAshaWorkerVerification(String email, String status) async {
    await init();
    if (_ashaWorkersSheet == null) {
      print("❌ Error: ASHA Workers Sheet Not Found!");
      return false;
    }

    try {
      final rows = await _ashaWorkersSheet!.values.allRows();
      for (int i = 1; i < rows.length; i++) {
        if (rows[i].length > 4 && rows[i][4] == email) {
          // Column E: Email
          await _ashaWorkersSheet!.values.insertValue(status,
              column: 9, row: i + 1); // Column I: Verification
          print("✅ ASHA Worker Verification Updated: $email → $status");
          return true;
        }
      }
      print("⚠️ ASHA Worker Not Found: $email");
      return false;
    } catch (e) {
      print("❌ Error Updating Verification: $e");
      return false;
    }
  }

  Future<bool> deleteAshaWorker(String email) async {
    await init();
    if (_ashaWorkersSheet == null) {
      print("❌ Error: ASHA Workers Sheet Not Found!");
      return false;
    }

    try {
      final rows = await _ashaWorkersSheet!.values.allRows();
      for (int i = 1; i < rows.length; i++) {
        if (rows[i].length > 4 && rows[i][4] == email) {
          // Column E: Email
          await _ashaWorkersSheet!.deleteRow(i + 1);
          print("✅ ASHA Worker Deleted: $email (Row ${i + 1})");
          return true;
        }
      }
      print("⚠️ ASHA Worker Not Found: $email");
      return false;
    } catch (e) {
      print("❌ Error Deleting ASHA Worker: $e");
      return false;
    }
  }

  Future<void> insertAdminNotification(String name, String blockNumber) async {
    await init();

    if (_adminNotificationSheet == null) {
      print('❌ Admin Notification Sheet Not Found!');
      return;
    }

    try {
      await _adminNotificationSheet!.values
          .appendRow(['$name ($blockNumber) verification pending']);

      print('✅ Notification Added: $name ($blockNumber) verification pending');
    } catch (e) {
      print('❌ Error Adding Notification: $e');
    }
  }

  /// ✅ Fetch Admin Notifications
  Future<List<List<String>>> fetchAdminNotifications() async {
    await init();

    if (_adminNotificationSheet == null) {
      print('❌ Admin Notification Sheet Not Found!');
      return [];
    }

    try {
      final allRows = await _adminNotificationSheet!.values.allRows();
      return allRows
          .map((row) => row.isNotEmpty ? row : ['', ''])
          .toList(); // ✅ Ensure two values per row
    } catch (e) {
      print('❌ Error Fetching Notifications: $e');
      return [];
    }
  }

  /// ✅ Delete Admin Notification
  Future<void> deleteAdminNotification(int rowIndex) async {
    await init();

    if (_adminNotificationSheet == null) {
      print('❌ Admin Notification Sheet Not Found!');
      return;
    }

    try {
      await _adminNotificationSheet!.deleteRow(rowIndex + 1);
      print('✅ Notification Deleted (Row $rowIndex)');
    } catch (e) {
      print('❌ Error Deleting Notification: $e');
    }
  }

// ✅ Add this function to save a notification when a user registers
  Future<void> addAshaNotification(
      String ashaWorkerBlock, String message) async {
    await init();

    if (_ashaNotificationSheet == null) {
      print('❌ ASHA Notification Sheet Not Found!');
      return;
    }

    try {
      await _ashaNotificationSheet!.values.appendRow(
          [ashaWorkerBlock, message, DateTime.now().toIso8601String()]);
      print('✅ Notification added for ASHA worker in block $ashaWorkerBlock');
    } catch (e) {
      print('❌ Error adding notification: $e');
    }
  }

// ✅ Fetch notifications for an ASHA worker based on their block number
  Future<List<Map<String, String>>> fetchAshaNotifications(
      String ashaWorkerBlock) async {
    await init();

    if (_ashaNotificationSheet == null) {
      print('❌ ASHA Notification Sheet Not Found!');
      return [];
    }

    try {
      final allRows = await _ashaNotificationSheet!.values.allRows();
      return allRows
          .where((row) => row.isNotEmpty && row[0] == ashaWorkerBlock)
          .map((row) => {
                "message": row.length > 1 ? row[1] : "Unknown notification",
                "date": row.length > 2 ? row[2] : "",
              })
          .toList();
    } catch (e) {
      print('❌ Error fetching ASHA notifications: $e');
      return [];
    }
  }

// ✅ Delete a specific notification (if needed)
  Future<void> deleteAshaNotification(int rowIndex) async {
    await init();

    if (_ashaNotificationSheet == null) {
      print('❌ ASHA Notification Sheet Not Found!');
      return;
    }

    try {
      await _ashaNotificationSheet!.deleteRow(rowIndex + 1);
      print('✅ Notification deleted successfully');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }
}
