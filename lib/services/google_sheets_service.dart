import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:flutter/services.dart';
import '../homepage/user_homepage.dart';
import '../homepage/asha_homepage.dart';
import 'package:collection/collection.dart';

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
  Worksheet? _pregnancySheet; // ✅ Declare pregnancy sheet
  Worksheet? _remindersSheet; // ✅ Declare reminders sheet
  Worksheet? _userNotification;
  Worksheet? _feedbacks;

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

      _pregnancySheet =
          await _getOrCreateSheet('pregnant'); // ✅ Initialize pregnancy sheet

      _remindersSheet = await _getOrCreateSheet('reminders');

      _userNotification = await _getOrCreateSheet('user_notifications');

      _feedbacks = await _getOrCreateSheet('feedbacks');

      _isInitialized = true;
      print("✅ Google Sheets Initialized Successfully");
    } catch (e) {
      print("❌ Error Initializing Google Sheets: $e");
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

  Future<List<Map<String, dynamic>>> fetchAshaNotifications(
      String email) async {
    await init(); // Ensure Sheets are initialized

    // ✅ Fetch ASHA Worker Block Number
    String? blockNumber = await getAshaWorkerBlockNumber(email);
    if (blockNumber == null) {
      print("❌ No block number found for ASHA worker with email: $email");
      return [];
    }
    print("✅ ASHA Worker Block Number: $blockNumber");

    // ✅ Ensure ASHA Notifications Sheet Exists
    if (_ashaNotificationSheet == null) {
      print("❌ Error: ASHA Notifications sheet not found!");
      return [];
    }

    // ✅ Fetch Raw Sheet Data (without mapping)
    final rawData = await _ashaNotificationSheet!.values.allRows();
    print("📝 Raw ASHA Notifications Data: $rawData");

    if (rawData.isEmpty) {
      print("⚠️ No notifications found in sheet!");
      return [];
    }

    // ✅ Extract Headers
    final headers = rawData.first;
    print("🔍 Detected Headers: $headers");

    // ✅ Ensure 'block_number' Column Exists
    if (!headers.contains('block_number')) {
      print(
          "❌ Error: 'block_number' column not detected in sheet! Check column names.");
      return [];
    }

    // ✅ Fetch All Notifications with Mapping
    final allNotifications =
        await _ashaNotificationSheet!.values.map.allRows() ?? [];
    print("✅ All ASHA Notifications (Mapped): $allNotifications");

    // ✅ Filter Notifications by Block Number
    final filteredNotifications = allNotifications
        .where((row) => row['block_number'].toString() == blockNumber)
        .toList();

    print(
        "✅ Filtered Notifications for block '$blockNumber': $filteredNotifications");

    return filteredNotifications;
  }

// ✅ Improved delete function to prevent index mismatch
  Future<void> deleteAshaNotification(int rowIndex) async {
    await init();

    if (_ashaNotificationSheet == null) {
      print('❌ ASHA Notification Sheet Not Found!');
      return;
    }

    try {
      final allRows = await _ashaNotificationSheet!.values.allRows();

      if (rowIndex >= allRows.length) {
        print('❌ Invalid index: $rowIndex. No such row exists.');
        return;
      }

      await _ashaNotificationSheet!.deleteRow(rowIndex + 1);
      print('✅ Notification deleted successfully (Row ${rowIndex + 1})');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  Future<Map<String, dynamic>> getAshaWorkerDetails(String email) async {
    await init(); // Ensure Google Sheets is initialized

    if (_ashaWorkersSheet == null) {
      print("❌ ASHA Workers Sheet Not Found!");
      return {};
    }

    try {
      final rows = await _ashaWorkersSheet!.values.allRows();
      if (rows.isEmpty) {
        print("❌ No ASHA workers data found.");
        return {};
      }

      // Find the ASHA worker by email
      for (var row in rows) {
        if (row.length > 4 && row[4] == email) {
          // Assuming Email is in Column E (Index 4)
          return {
            'name': row[0], // Adjust based on actual column order
            'block_number':
                row[2], // Assuming Block Number is in Column C (Index 2)
          };
        }
      }

      print("❌ ASHA worker not found with email: $email");
      return {};
    } catch (e) {
      print("❌ Error fetching ASHA worker details: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String email) async {
    await init(); // Ensure Google Sheets is initialized

    if (_usersSheet == null) {
      print("❌ ASHA User Sheet Not Found!");
      return {};
    }

    try {
      final rows = await _usersSheet!.values.allRows();
      if (rows.isEmpty) {
        print("❌ No ASHA user data found.");
        return {};
      }

      // Find the user by email
      for (var row in rows) {
        if (row.length > 2 && row[2] == email) {
          // Email in Column C (Index 2)
          return {
            'name': row[0], // Name in Column A (Index 0)
            'phone': row[1], // Phone in Column B (Index 1)
            'email': row[2], // Email in Column C (Index 2)
            'address': row[3], // Address in Column D (Index 3)
            'block_number': row[4], // Block Number in Column E (Index 4)
            'dob': row[5], // DOB in Column F (Index 5)
            'category': row[6], // Category in Column G (Index 6)
            'age': row[8], // Age in Column I (Index 8)
          };
        }
      }

      print("❌ User not found with email: $email");
      return {};
    } catch (e) {
      print("❌ Error fetching user details: $e");
      return {};
    }
  }

  Future<void> updateUserDetails(
      String email, Map<String, String> updatedData) async {
    await init(); // Ensure Google Sheets is initialized

    if (_usersSheet == null) {
      print("❌ Users Sheet Not Found!");
      return;
    }

    try {
      final rows = await _usersSheet!.values.allRows();

      if (rows.isEmpty) {
        print("⚠️ Google Sheets is empty!");
        return;
      }

      print(
          "📄 All rows from Google Sheets: $rows"); // Debugging: Print all data

      for (var i = 0; i < rows.length; i++) {
        print("🔍 Checking row ${i + 1}: ${rows[i]}"); // Debug each row
        print(
            "🆔 Comparing: '${rows[i][2]}' vs '${email.trim().toLowerCase()}'"); // Print email comparison

        if (rows[i].length > 2 &&
            rows[i][2].trim().toLowerCase() == email.trim().toLowerCase()) {
          // ✅ User found, updating details

          // Get the updated or existing DOB
          String dob = updatedData["dob"] ?? rows[i][5];

          // ✅ Calculate Age
          int age = _calculateAge(dob);

          await _usersSheet!.values.insertRow(
              i + 1,
              [
                updatedData["name"] ?? rows[i][0], // Name
                updatedData["phone"] ?? rows[i][1], // Phone
                email, // Email (unchanged)
                updatedData["address"] ?? rows[i][3], // Address
                rows[i][4], // Block Number (unchanged)
                dob, // ✅ Updated DOB
                updatedData["category"] ?? rows[i][6], // Category (unchanged)
                rows[i][7], // Password (unchanged)
                age.toString(), // ✅ Updated Age
              ],
              fromColumn: 1);

          print("✅ User details updated successfully with new age: $age");
          return;
        }
      }

      print("❌ User not found in Google Sheets!");
    } catch (e) {
      print("❌ Error updating user details: $e");
    }
  }

  /// ✅ Function to Calculate Age from DOB
  int _computeAgeFromDOB(String dob) {
    try {
      DateTime birthDate = DateTime.parse(dob);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      print("❌ Error calculating age: $e");
      return 0;
    }
  }

  Future<void> updateUserPassword(String email, String newPassword) async {
    await init(); // Ensure Google Sheets is initialized

    if (_usersSheet == null) {
      print("❌ Users Sheet Not Found!");
      return;
    }

    try {
      final rows = await _usersSheet!.values.allRows();

      if (rows.isEmpty) {
        print("⚠️ Google Sheets is empty!");
        return;
      }

      print(
          "📄 All rows from Google Sheets: $rows"); // Debugging: Print all data

      for (var i = 0; i < rows.length; i++) {
        print("🔍 Checking row ${i + 1}: ${rows[i]}"); // Debug each row
        print(
            "🆔 Comparing: '${rows[i][2]}' vs '${email.trim().toLowerCase()}'"); // Print email comparison

        if (rows[i].length > 2 &&
            rows[i][2].trim().toLowerCase() == email.trim().toLowerCase()) {
          // ✅ User found, updating password
          await _usersSheet!.values.insertRow(
              i + 1,
              [
                rows[i][0], // Name
                rows[i][1], // Phone
                email, // Email (unchanged)
                rows[i][3], // Address
                rows[i][4], // Block Number (unchanged)
                rows[i][5], // Date of Birth
                rows[i][6], // Category (unchanged)
                newPassword, // ✅ Updated Password
                rows[i][8], // Age (unchanged)
              ],
              fromColumn: 1);

          print("✅ Password updated successfully!");
          return;
        }
      }

      print("❌ User not found in Google Sheets!");
    } catch (e) {
      print("❌ Error updating password: $e");
    }
  }

  Future<void> updateAshaWorkerPassword(
      String email, String newPassword) async {
    await init(); // Ensure Google Sheets is initialized

    if (_ashaWorkersSheet == null) {
      print("❌ ASHA Workers Sheet Not Found!");
      return;
    }

    try {
      final rows = await _ashaWorkersSheet!.values.allRows();

      for (var i = 0; i < rows.length; i++) {
        if (rows[i].length > 4 && rows[i][4] == email) {
          // Email is in Column 4 (Index 4)
          await _ashaWorkersSheet!.values.insertRow(
            i + 1,
            [
              rows[i][0], // ID (Unchanged)
              rows[i][1], // Name (Unchanged)
              rows[i][2], // Phone (Unchanged)
              rows[i][3], // Block Number (Unchanged)
              rows[i][4], // Email (Unchanged)
              rows[i][5], // ID URL (Unchanged)
              rows[i][6], // Username (Unchanged)
              newPassword, // ✅ Updated Password
              rows[i][8], // Verification Status (Unchanged)
            ],
            fromColumn: 1,
          );

          print("✅ ASHA Worker Password Updated Successfully!");
          return;
        }
      }
      print("❌ ASHA Worker Not Found!");
    } catch (e) {
      print("❌ Error Updating Password: $e");
    }
  }

  Future<void> updateAshaWorkerDetails(
      String email, Map<String, String> updatedData) async {
    await init(); // Ensure Google Sheets is initialized

    if (_ashaWorkersSheet == null) {
      print("❌ ASHA Workers Sheet Not Found!");
      return;
    }

    try {
      final allRows = await _ashaWorkersSheet!.values.allRows();
      int? targetRowIndex;

      // ✅ Find the row index where the email matches (Email is in Column 4)
      for (var i = 0; i < allRows.length; i++) {
        if (allRows[i].length > 4 && allRows[i][4] == email) {
          targetRowIndex = i + 1; // Google Sheets uses 1-based index
          break;
        }
      }

      if (targetRowIndex == null) {
        print("❌ ASHA Worker Not Found!");
        return;
      }

      // ✅ Prepare the updated row, keeping existing values if not provided
      List<String> updatedRow = [
        allRows[targetRowIndex - 1][0], // ID (Unchanged)
        updatedData["name"] ?? allRows[targetRowIndex - 1][1], // Name
        updatedData["phone"] ?? allRows[targetRowIndex - 1][2], // Phone
        allRows[targetRowIndex - 1][3], // Block Number (Unchanged)
        email, // Email (Unchanged)
        allRows[targetRowIndex - 1][5], // ID URL (Unchanged)
        allRows[targetRowIndex - 1][6], // Username (Unchanged)
        allRows[targetRowIndex - 1][7], // Password (Unchanged)
        allRows[targetRowIndex - 1][8], // Verification Status (Unchanged)
      ];

      // ✅ Update the row in Google Sheets
      await _ashaWorkersSheet!.values.insertRow(targetRowIndex, updatedRow);

      print("✅ ASHA Worker Details Updated Successfully!");
    } catch (e) {
      print("❌ Error Updating ASHA Worker Details: $e");
    }
  }

  Future<Map<String, dynamic>> getAshaWorkerProfileDetails(String email) async {
    await init(); // Ensure Google Sheets is initialized

    if (_ashaWorkersSheet == null) {
      print("❌ ASHA Workers Sheet Not Found!");
      return {};
    }

    try {
      final rows = await _ashaWorkersSheet!.values.allRows();
      if (rows.isEmpty) {
        print("❌ No ASHA workers data found.");
        return {};
      }

      print("🔍 Searching for ASHA Worker with Email: $email");

      // Iterate over rows to find the ASHA worker by email
      for (var row in rows) {
        if (row.length > 4 &&
            row[4].trim().toLowerCase() == email.trim().toLowerCase()) {
          // Email is in Column E (Index 4)
          print("✅ ASHA Worker Found: $row");

          return {
            'id': row.isNotEmpty ? row[0] : "N/A", // ✅ ID in Column A (Index 0)
            'name':
                row.length > 1 ? row[1] : "N/A", // ✅ Name in Column B (Index 1)
            'phone': row.length > 2
                ? row[2]
                : "N/A", // ✅ Phone in Column C (Index 2)
            'block_number': row.length > 3
                ? row[3]
                : "N/A", // ✅ Block Number in Column D (Index 3)
            'email': row.length > 4
                ? row[4]
                : "N/A", // ✅ Email in Column E (Index 4)
            'username': row.length > 6
                ? row[6]
                : "N/A", // ✅ Username in Column G (Index 6)
            'verification': row.length > 8
                ? row[8]
                : "N/A", // ✅ Verification in Column I (Index 8)
            'id_url': row.length > 9
                ? row[9]
                : "", // ✅ ID URL in Column J (Index 9) if present
          };
        }
      }

      print("❌ No ASHA worker found for email: $email");
      return {};
    } catch (e) {
      print("❌ Error fetching ASHA worker details: $e");
      return {};
    }
  }

  /// ✅ Save Pregnancy Data
  Future<void> savePregnancyData({
    required String userEmail,
    required int weeksPregnant, // ✅ Corrected name
    required String expectedDueDate,
    required String blockNumber,
  }) async {
    if (_pregnancySheet == null) await init();

    await _pregnancySheet!.values.appendRow([
      userEmail,
      weeksPregnant.toString(), // ✅ Ensure weeksPregnant is used correctly
      expectedDueDate,
      blockNumber,
    ]);

    print("✅ Pregnancy data saved for $userEmail in block $blockNumber");
  }

  /// ✅ Get Pregnancy Data
  Future<Map<String, String>?> getPregnancyData(String userEmail) async {
    if (_pregnancySheet == null) await init();

    final allRows = await _pregnancySheet!.values.map.allRows();

    if (allRows == null || allRows.isEmpty) {
      print("⚠️ Warning: No pregnancy data found in Google Sheets!");
      return null;
    }

    for (var row in allRows) {
      if (row['email'] == userEmail) {
        return {
          'weeks_pregnant': row['weeks_pregnant'] ?? '0',
          'expected_due_date': row['expected_due_date'] ?? '',
          'block_number': row['block_number'] ?? '',
        };
      }
    }

    print("⚠️ No pregnancy data found for $userEmail");
    return null;
  }

  Future<List<Map<String, String>>> getPregnantWomenByBlock(
      String blockNumber) async {
    if (_pregnancySheet == null) await init();

    final allRows = await _pregnancySheet!.values.map.allRows() ?? [];
    return allRows
        .where((row) => row['block_number'] == blockNumber)
        .map((row) => {
              'email': row['email'] ?? '',
              'weeks_pregnant': row['weeks_pregnant'] ?? '0',
              'expected_due_date': row['expected_due_date'] ?? '',
            })
        .toList();
  }

  Future<List<Map<String, String>>> getRemindersForPregnantWoman(
      String email) async {
    if (_remindersSheet == null) await init();

    final allRows = await _remindersSheet!.values.map.allRows() ?? [];

    return allRows
        .where((row) => row['email'] == email)
        .map((row) => {
              'reminder': row['reminder'] ?? 'No reminder',
              'date': row['date'] ?? 'No date',
            })
        .toList();
  }

  Future<void> addReminder({
    required String email,
    required String reminder,
    required String date,
  }) async {
    if (!_isInitialized) await init();

    if (_remindersSheet == null || _userNotification == null) {
      print("❌ Error: One or more sheets are NULL!");
      return;
    }

    try {
      // ✅ Add the reminder to the reminders sheet
      await _remindersSheet!.values.appendRow([email, reminder, date]);
      print("✅ Reminder added: $reminder on $date for $email");

      // ✅ Also add a notification to the user_notification sheet
      await _userNotification!.values.appendRow([email, reminder]);
      print("📢 Notification sent to user: $email");
    } catch (e) {
      print("❌ Error adding reminder or notification: $e");
    }
  }

  Future<String?> getAshaBlockNumber(String ashaEmail) async {
    if (!_isInitialized) {
      await init();
    }

    if (_ashaWorkersSheet == null) {
      print("❌ ASHA Workers sheet not found!");
      return null;
    }

    try {
      final allRows = await _ashaWorkersSheet!.values.allRows();
      for (var row in allRows) {
        if (row.length > 5 && row[4].trim() == ashaEmail) {
          String blockNumber = row[3].trim();
          print("✅ ASHA Worker Block Number Found: $blockNumber");
          return blockNumber;
        }
      }

      print("❌ No block number found for ASHA worker: $ashaEmail");
      return null;
    } catch (e) {
      print("❌ Error fetching ASHA block number: $e");
      return null;
    }
  }

  Future<List<Map<String, String>>> getReminders(String userEmail) async {
    List<Map<String, String>> remindersList = [];

    GoogleSheetsService gsheetsService = GoogleSheetsService();
    await gsheetsService.init();

    final sheet = gsheetsService._remindersSheet;
    if (sheet == null) {
      print("❌ Error: Reminders sheet not found");
      return remindersList;
    }

    final allRows = await sheet.values.map.allRows();
    if (allRows == null) {
      print("❌ Error: No data found in reminders sheet");
      return remindersList;
    }

    for (var row in allRows) {
      if (row['email'] == userEmail) {
        String rawDate = row['date'] ?? '';
        String reminderText = row['reminder'] ?? '';

        if (rawDate.isNotEmpty) {
          remindersList.add({
            "date": rawDate, // ✅ Keep the date as a string (plain text format)
            "reminder": reminderText,
          });
        }
      }
    }

    print("✅ Reminders Fetched: $remindersList");
    return remindersList;
  }

  // ✅ Fetch notifications for the logged-in user
  Future<List<Map<String, String>>> getUserNotifications(String email) async {
    await init(); // Ensure Google Sheets is initialized
    if (_userNotification == null) {
      print("❌ Error: User Notification sheet is NULL!");
      return [];
    }

    final allRows = await _userNotification!.values.map.allRows();
    if (allRows == null) return [];

    // Filter notifications by user email
    return allRows
        .where((row) => row['email'] == email)
        .map((row) => {'email': row['email']!, 'message': row['message']!})
        .toList();
  }

// ✅ Delete a notification when marked as read
  Future<void> deleteUserNotification(String email, String message) async {
    await init(); // Ensure Google Sheets is initialized
    if (_userNotification == null) {
      print("❌ Error: User Notification sheet is NULL!");
      return;
    }

    final allRows = await _userNotification!.values.map.allRows();
    if (allRows == null) return;

    for (int i = 0; i < allRows.length; i++) {
      if (allRows[i]['email'] == email && allRows[i]['message'] == message) {
        await _userNotification!.deleteRow(i + 2); // +2 to account for headers
        print("✅ Notification deleted: $message");
        return;
      }
    }
  }

  Future<void> submitFeedback(String role, String feedback) async {
    if (!_isInitialized) {
      await init(); // Ensure Google Sheets is initialized
    }

    if (_feedbacks == null) {
      print("❌ Error: Feedbacks sheet is NULL!");
      return;
    }

    try {
      // Append the feedback to the 'feedbacks' sheet.  Crucially, we now specify the data as a list.
      print(
          "Submitting feedback: role='$role', feedback='$feedback', timestamp=${DateTime.now().toIso8601String()}");
      await _feedbacks!.values
          .appendRow([role, feedback, DateTime.now().toIso8601String()]);
      print("✅ Feedback submitted successfully for role: $role!");
    } catch (e) {
      print("❌ Error submitting feedback: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeedbacks() async {
    // Removed role parameter
    await init();
    if (_feedbacks == null) {
      print("❌ Error: Feedbacks sheet is NULL! Initialization failed.");
      return [];
    }

    List<Map<String, dynamic>> feedbacks = [];
    try {
      final allRows = await _feedbacks!.values.allRows();
      if (allRows == null || allRows.isEmpty) {
        print("⚠️ Warning: No feedback data found in the 'feedbacks' sheet.");
        return feedbacks;
      }

      for (var i = 1; i < allRows.length; i++) {
        // Skip header row
        if (allRows[i].length >= 3) {
          // Check for sufficient data
          feedbacks.add({
            'role': allRows[i][0] ?? '',
            'feedback': allRows[i][1] ?? '',
            'timestamp': allRows[i][2] ?? '',
            'rowIndex': i + 1,
          });
        } else {
          print(
              "⚠️ Warning: Row $i in 'feedbacks' sheet has insufficient data. Skipping...");
        }
      }
    } catch (e) {
      print("❌ Error fetching feedbacks: $e");
    }
    return feedbacks;
  }

  Future<bool> deleteFeedback(int rowIndex) async {
    await init();
    if (_feedbacks == null) {
      print("❌ Error: Feedbacks sheet is NULL!");
      return false;
    }
    try {
      await _feedbacks!.deleteRow(rowIndex);
      print("✅ Feedback deleted successfully (row: $rowIndex)");
      return true;
    } catch (e) {
      print("❌ Error deleting feedback: $e");
      return false;
    }
  }

  Future<bool> isBlockNumberUnique(String blockNumber) async {
    await init();
    if (_ashaWorkersSheet == null) {
      print("❌ Error: ASHA Workers Sheet Not Found!");
      return false; // Assume not unique if sheet not found
    }

    try {
      final allRows = await _ashaWorkersSheet!.values.allRows();
      for (var row in allRows) {
        if (row.length > 3 && row[3] == blockNumber) {
          // Assuming block number is in column 4 (index 3)
          return false; // Block number already exists
        }
      }
      return true; // Block number is unique
    } catch (e) {
      print("❌ Error checking block number uniqueness: $e");
      return false; // Assume not unique if error occurs
    }
  }

  Future<String?> getUserCategory(String userEmail) async {
    await init(); // Ensure Google Sheets is initialized

    if (_usersSheet == null) {
      print("❌ Error: Users sheet not found!");
      return null;
    }

    try {
      final rows = await _usersSheet!.values.allRows();
      if (rows == null || rows.isEmpty) {
        print("⚠️ Warning: No data found in the 'Users' sheet.");
        return null;
      }

      // Efficiently find the user using firstWhereOrNull
      final userRow = rows.firstWhereOrNull(
          (row) => row[2] == userEmail); // Email is in column C (index 2)

      if (userRow == null) {
        print("❌ User with email '$userEmail' not found in the 'Users' sheet.");
        return null;
      }

      // Safely access the category (column G, index 6)
      return userRow[6]?.toString();
    } catch (e, stacktrace) {
      print("❌ Error fetching user category: $e\n$stacktrace");
      return null;
    }
  }
}
