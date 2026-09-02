import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'about_model.dart';

class AboutService {
  static const String primaryAdminEmail = 'dev.harshitcreations@gmail.com';
  static const String _prefsKey = 'strawberry_about_info_v4';
  static const String _tableName = 'about_info';

  final SupabaseClient _client = Supabase.instance.client;

  /// Checks if the given email belongs to the primary administrator.
  static bool isPrimaryAdmin(String? email) {
    if (email == null) return false;
    return email.trim().toLowerCase() == primaryAdminEmail.toLowerCase();
  }

  /// Fetches the latest About info with cache-first strategy.
  Future<AboutInfo> getAboutInfo() async {
    AboutInfo current = AboutInfo.defaults();

    // 1. Read from local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefsKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        current = AboutInfo.fromJson(cachedJson);
      }
    } catch (_) {}

    // 2. Fetch from Supabase
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final remote = AboutInfo.fromMap(response);
        // Cache remote data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, remote.toJson());
        return remote;
      }
    } catch (_) {
      // Table may not exist yet or offline; fallback to cached/defaults
    }

    return current;
  }

  /// Updates About info in both Supabase and local cache.
  Future<void> saveAboutInfo(AboutInfo info) async {
    // 1. Cache immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, info.toJson());
    } catch (_) {}

    // 2. Persist to Supabase
    try {
      final data = info.toMap();
      data['id'] = 1; // Single row key
      await _client.from(_tableName).upsert(data);
    } catch (_) {
      // If table doesn't exist, we still have local cache and can log
    }
  }

  /// Compresses and uploads an image to Supabase storage.
  Future<String> uploadImage(dynamic file, {String prefix = 'about'}) async {
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Uint8List bytes;

    if (file is XFile) {
      bytes = await file.readAsBytes();
    } else if (file is File) {
      if (!kIsWeb) {
        final compressed = await _compressImage(file);
        bytes = await compressed.readAsBytes();
      } else {
        bytes = await file.readAsBytes();
      }
    } else {
      throw ArgumentError('Unsupported file type');
    }

    await _client.storage
        .from('gallery')
        .uploadBinary(fileName, bytes);

    return _client.storage.from('gallery').getPublicUrl(fileName);
  }

  Future<File> _compressImage(File file) async {
    if (kIsWeb) return file;
    const maxSize = 500 * 1024; // 500KB
    var quality = 90;
    File? compressedFile = file;

    try {
      while (true) {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          '${file.path}_compressed.jpg',
          quality: quality,
        );
        if (result == null) break;
        final asFile = File(result.path);
        final size = await asFile.length();
        compressedFile = asFile;
        if (size <= maxSize || quality <= 30) {
          break;
        }
        quality -= 15;
      }
    } catch (_) {
      return file;
    }
    return compressedFile ?? file;
  }
}
