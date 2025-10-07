import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: Constants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: Constants.tokenKey);
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: Constants.refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: Constants.refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: Constants.tokenKey);
    await _secureStorage.delete(key: Constants.refreshTokenKey);
  }

  // User data
  static Future<void> saveUser(User user) async {
    await _prefs?.setString(Constants.userDataKey, jsonEncode(user.toJson()));
  }

  static User? getUser() {
    final userData = _prefs?.getString(Constants.userDataKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  static Future<void> clearUser() async {
    await _prefs?.remove(Constants.userDataKey);
  }

  // General preferences
  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String getString(String key, {String defaultValue = ''}) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  // Clear all data
  static Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    await _prefs?.clear();
  }
}