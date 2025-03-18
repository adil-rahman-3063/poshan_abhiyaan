import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth; // ✅ Correct import
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  late auth.AuthClient _client;
  late drive.DriveApi _driveApi;
  bool _isInitialized = false; // Prevent multiple initializations

  static const String _credentialsFile =
      "assets/service_account.json"; // ✅ Defined

  /// ✅ Initialize Google Drive API
  Future<void> init() async {
    if (_isInitialized) return; // Prevent multiple initializations

    try {
      print("⏳ Initializing Google Drive...");

      // Load service account JSON credentials
      final jsonString = await rootBundle.loadString(_credentialsFile);
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonString);

      // Authenticate using Service Account
      _client = await auth.clientViaServiceAccount(
        // ✅ Function now recognized
        credentials,
        [drive.DriveApi.driveFileScope],
      );

      // Initialize Google Drive API
      _driveApi = drive.DriveApi(_client);
      _isInitialized = true;

      print("✅ Google Drive initialized successfully!");
    } catch (e) {
      print("❌ Error initializing Google Drive: $e");
    }
  }

  /// ✅ Upload File to Google Drive
  Future<String?> uploadFile(File file) async {
    await init(); // Ensure Drive API is initialized
    if (!_isInitialized) {
      print("❌ Google Drive initialization failed!");
      return null;
    }

    try {
      const String folderId =
          "1CLVcKnxor6ITaQuQE-y4wWLLonL2BRU_"; // Your folder ID

      print("📂 Uploading to Folder ID: $folderId");

      var driveFile = drive.File();
      driveFile.name = file.path.split('/').last;
      driveFile.parents = [folderId]; // Directly use folder ID

      var media = drive.Media(file.openRead(), file.lengthSync());

      final uploadedFile = await _driveApi.files.create(
        driveFile,
        uploadMedia: media,
        supportsAllDrives: true, // Ensure support for shared folders
      );

      print("✅ Upload successful: ${uploadedFile.id}");
      return uploadedFile.id;
    } catch (e) {
      print("❌ Error uploading file: $e");
      return null;
    }
  }

  /// ✅ Get or create folder in Google Drive
  Future<String?> getOrCreateFolder(
    drive.DriveApi driveApi, String folderName, {String? sharedDriveId}) async {
  try {
    // 🔍 Query to find the folder
    String query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";

    Map<String, dynamic> queryParams = {
      'q': query,
      'spaces': "drive",
      'supportsAllDrives': true,
      'includeItemsFromAllDrives': true,
    };

    // 📂 If using a Shared Drive, set `corpora` and `driveId`
    if (sharedDriveId != null) {
      queryParams['corpora'] = "drive";
      queryParams['driveId'] = sharedDriveId;
    }

    var folderList = await driveApi.files.list(
      q: query,
      spaces: "drive",
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
      corpora: sharedDriveId != null ? "drive" : "user", // Adjust corpora
      driveId: sharedDriveId,
    );

    // ✅ Folder exists
    if (folderList.files != null && folderList.files!.isNotEmpty) {
      print("✅ Folder '$folderName' found: ${folderList.files!.first.id}");
      return folderList.files!.first.id;
    }

    // 🚀 Create folder if not found
    print("⚠️ Folder '$folderName' not found, creating...");
    var folder = drive.File();
    folder.name = folderName;
    folder.mimeType = "application/vnd.google-apps.folder";

    // 📂 Set parent folder ID
    if (sharedDriveId != null) {
      folder.driveId = sharedDriveId; // For Shared Drive
    } else {
      folder.parents = ["1CLVcKnxor6ITaQuQE-y4wWLLonL2BRU_"]; // Your My Drive folder ID
    }

    var createdFolder = await driveApi.files.create(
      folder,
      supportsAllDrives: true,
    );

    print("✅ Folder '$folderName' created: ${createdFolder.id}");
    return createdFolder.id;
  } catch (e) {
    print("❌ Error creating/finding folder: $e");
    return null;
  }
}

}
