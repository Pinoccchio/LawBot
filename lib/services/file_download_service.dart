import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileDownloadService {
  static final Dio _dio = Dio();
  static final _supabase = Supabase.instance.client;

  /// Download a file from URL and save it locally
  static Future<String?> downloadFile({
    required String url,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Request storage permission
      await _requestStoragePermission();

      // Get the download directory
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        print('File already exists at: $filePath');
        return filePath;
      }

      // Download the file
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received, total);
          }
          print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
        },
        options: Options(
          headers: {
            'Accept': '*/*',
          },
        ),
      );

      print('File downloaded successfully to: $filePath');
      return filePath;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  /// Download file from Supabase storage
  static Future<String?> downloadFromSupabase({
    required String bucketName,
    required String path,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Get the public URL from Supabase
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      print('Downloading from Supabase URL: $publicUrl');

      // Use the general download method
      return await downloadFile(
        url: publicUrl,
        fileName: fileName,
        onProgress: onProgress,
      );
    } catch (e) {
      print('Error downloading from Supabase: $e');
      return null;
    }
  }

  /// Open a file using the system's default app
  static Future<bool> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {
        print('File opened successfully');
        return true;
      } else {
        print('Error opening file: ${result.message}');
        return false;
      }
    } catch (e) {
      print('Exception opening file: $e');
      return false;
    }
  }

  /// Open a file from URL (download first if needed)
  static Future<bool> openFileFromUrl({
    required String url,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // First try to download the file
      final localPath = await downloadFile(
        url: url,
        fileName: fileName,
        onProgress: onProgress,
      );

      if (localPath != null) {
        // Open the downloaded file
        return await openFile(localPath);
      }

      return false;
    } catch (e) {
      print('Error opening file from URL: $e');
      return false;
    }
  }

  /// Request storage permission
  static Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need different permissions
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      
      // For older Android versions
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }
  }

  /// Get the appropriate download directory
  static Future<Directory> _getDownloadDirectory() async {
    Directory directory;

    if (Platform.isAndroid) {
      // Try to get the Downloads folder on Android
      directory = Directory('/storage/emulated/0/Download');
      
      // If it doesn't exist, try with 's' at the end
      if (!await directory.exists()) {
        directory = Directory('/storage/emulated/0/Downloads');
      }
      
      // If still doesn't exist, use external storage directory
      if (!await directory.exists()) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          directory = externalDir;
        } else {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      }
    } else if (Platform.isIOS) {
      // For iOS, use documents directory
      directory = await getApplicationDocumentsDirectory();
    } else {
      // For other platforms
      directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }

    // Create directory if it doesn't exist
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  /// Get file name from URL
  static String getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
}