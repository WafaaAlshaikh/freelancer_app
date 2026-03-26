// lib/utils/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String tokenKey = "auth_token";
  static const String userRoleKey = "user_role";
  static const String supabaseUserIdKey = "supabase_user_id"; 

  // ========== Token APIs ==========
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    print('✅ Token saved');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    print('✅ Token cleared');
  }

  // ========== User Role APIs ==========
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userRoleKey, role);
    print('✅ User role saved: $role');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userRoleKey);
  }

  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userRoleKey);
    print('✅ User role cleared');
  }

  // ========== Supabase User ID APIs ==========
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

  // ========== Check Login Status ==========
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isSupabaseLoggedIn() async {
    final userId = await getSupabaseUserId();
    return userId != null && userId.isNotEmpty;
  }

  // ========== Get All Stored Data ==========
  static Future<Map<String, dynamic>> getAllData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(tokenKey),
      'userRole': prefs.getString(userRoleKey),
      'supabaseUserId': prefs.getString(supabaseUserIdKey),
    };
  }

  // ========== Clear All Data ==========
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ All data cleared');
  }

  static Future<void> clearAuthData() async {
    await clearToken();
    await clearUserRole();
    await clearSupabaseUserId();
    print('✅ Auth data cleared');
  }
}