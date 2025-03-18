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
  bool _isInitialized = false;

  GoogleSheetsService();

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

      _isInitialized = true;
      print("✅ Google Sheets Initialized Successfully");
    } catch (e) {
      print("❌ Error Initializing Google Sheets: $e");
    }
  }

  /// Ensure a worksheet exists, create if missing
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

    if (_ashaWorkersSheet == null) {
      print('❌ ASHA Workers Sheet Not Found!');
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
      ]);

      print('✅ ASHA Worker Registered: $name (ID: $newId)');
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

    // ✅ If input is already an email, return it
    if (usernameOrEmail.contains('@')) {
      return usernameOrEmail;
    }

    // 🔍 Search ASHA Workers by username
    for (var worker in workers) {
      if (worker['username'] == usernameOrEmail) {
        return worker['email'];
      }
    }

    // 🔍 Search Admins by username
    for (var admin in admins) {
      if (admin['username'] == usernameOrEmail) {
        return admin['email'];
      }
    }

    return null; // ❌ Email not found
  }
}
