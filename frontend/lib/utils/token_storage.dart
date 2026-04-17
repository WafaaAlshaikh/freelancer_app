// lib/utils/token_storage.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenStorage {
  static const String tokenKey = "auth_token";
  static const String userRoleKey = "user_role";
  static const String userIdKey = "user_id";
  static const String supabaseUserIdKey = "supabase_user_id";
  static const String userKey = "user_data";

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    print(
      '✅ Token saved: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
    );
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    print(
      '🔑 Token retrieved: ${token != null ? 'exists (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'null'}',
    );
    return token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    print('✅ Token cleared');
  }

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId.toString());
    print('✅ User ID saved: $userId');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(userIdKey);
    print('👤 User ID retrieved: $userId');
    return userId;
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
    print('✅ User ID cleared');
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
    print('✅ User data saved: ${user['id']} - ${user['name']}');
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson != null) {
      try {
        final user = jsonDecode(userJson);
        print('👤 User data retrieved: ${user['id']} - ${user['name']}');
        return user;
      } catch (e) {
        print('❌ Error parsing user data: $e');
        return null;
      }
    }
    print('👤 No user data found');
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
    print('✅ User data cleared');
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userRoleKey, role);
    print('✅ User role saved: $role');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(userRoleKey);
    print('👤 User role retrieved: $role');
    return role;
  }

  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userRoleKey);
    print('✅ User role cleared');
  }

  static Future<void> saveSupabaseUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(supabaseUserIdKey, userId);
    print('✅ Supabase user ID saved: $userId');
  }

  static Future<String?> getSupabaseUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(supabaseUserIdKey);
  }

  static Future<void> clearSupabaseUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(supabaseUserIdKey);
    print('✅ Supabase user ID cleared');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final userId = await getUserId();
    final isLoggedIn = token != null && token.isNotEmpty && userId != null;
    print(
      '🔐 Login status check: $isLoggedIn (token: ${token != null}, userId: $userId)',
    );
    return isLoggedIn;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ All SharedPreferences data cleared');
  }

  static Future<void> clearAuthData() async {
    await clearToken();
    await clearUserRole();
    await clearUserId();
    await clearSupabaseUserId();
    await clearUser();
    print('✅ All auth data cleared');
  }
}
