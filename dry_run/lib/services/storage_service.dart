import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _checkInsKey = "check_ins";

  static Future<void> saveCheckIns(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkInsKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> loadCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_checkInsKey);

    if (raw == null) return {};

    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}