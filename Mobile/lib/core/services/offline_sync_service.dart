import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineSyncService {
  static const String _keyRegistrationDraft = 'milklink_offline_reg_draft';
  static const String _keyPickupDraft = 'milklink_offline_pickup_draft';
  static const String _keyRequestDraft = 'milklink_offline_request_draft';

  // Save Registration Draft
  static Future<void> saveRegistrationDraft(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegistrationDraft, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getRegistrationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyRegistrationDraft);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clearRegistrationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRegistrationDraft);
  }

  // Save Pickup Draft
  static Future<void> savePickupDraft(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPickupDraft, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getPickupDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyPickupDraft);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clearPickupDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPickupDraft);
  }
}
