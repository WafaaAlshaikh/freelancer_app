import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';
import '../utils/token_storage.dart';
import 'api_service.dart';

class ProfileApiService {
  static String get baseUrl => BASE_URL;
  static Map<String, String> get headers => ApiService.headers;

  // ─── Freelancer ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyFreelancerProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/profiles/me/freelancer'),
        headers: headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {};
    } catch (e) {
      print('getMyFreelancerProfile: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerPublicProfile(
    int userId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/profiles/freelancer/$userId'),
        headers: headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateFreelancerProfile(
    Map<String, dynamic> data, {
    Uint8List? avatarBytes,
    String? avatarFileName,
    Uint8List? coverBytes,
    String? coverFileName,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profiles/me/freelancer'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      data.forEach((key, value) {
        if (value != null) {
          if (value is List || value is Map) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      if (avatarBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            avatarBytes,
            filename: avatarFileName ?? 'avatar.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      if (coverBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'cover',
            coverBytes,
            filename: coverFileName ?? 'cover.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      print('updateFreelancerProfile: $e');
      return {'message': 'Connection error'};
    }
  }

  // ─── Client ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyClientProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/profiles/me/client'),
        headers: headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getClientPublicProfile(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/profiles/client/$userId'),
        headers: headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateClientProfile(
    Map<String, dynamic> data, {
    Uint8List? avatarBytes,
    String? avatarFileName,
    Uint8List? coverBytes,
    String? coverFileName,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profiles/me/client'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      data.forEach((key, value) {
        if (value != null) {
          if (value is List || value is Map) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      if (avatarBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            avatarBytes,
            filename: avatarFileName ?? 'avatar.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      if (coverBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'cover',
            coverBytes,
            filename: coverFileName ?? 'cover.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> uploadCompanyLogo(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profiles/me/client/logo'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'logo',
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'message': 'Connection error'};
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> searchFreelancers({
    String? q,
    String? skills,
    double? minRate,
    double? maxRate,
    String? availability,
    double? minRating,
    String? location,
    String sort = 'rating',
    int page = 1,
  }) async {
    try {
      final params = <String, String>{
        'sort': sort,
        'page': '$page',
        if (q != null && q.isNotEmpty) 'q': q,
        if (skills != null) 'skills': skills,
        if (minRate != null) 'min_rate': '$minRate',
        if (maxRate != null) 'max_rate': '$maxRate',
        if (availability != null) 'availability': availability,
        if (minRating != null) 'min_rating': '$minRating',
        if (location != null) 'location': location,
      };
      final uri = Uri.parse(
        '$baseUrl/profiles/freelancers/search',
      ).replace(queryParameters: params);
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {'freelancers': [], 'total': 0};
    } catch (e) {
      return {'freelancers': [], 'total': 0};
    }
  }

  static String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'http://localhost:5000$path';
  }
}
