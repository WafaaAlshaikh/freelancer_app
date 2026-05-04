// lib/services/profile_api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart' show BASE_URL, apiMediaUrl;
import '../utils/token_storage.dart';
import 'api_service.dart';

class ProfileApiService {
  static String get baseUrl => BASE_URL;
  static Map<String, String> get headers => ApiService.headers;

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
          } else if (value is DateTime) {
            request.fields[key] = value.toIso8601String();
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

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return jsonDecode(body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${streamed.statusCode}',
        };
      }
    } catch (e) {
      print('updateFreelancerProfile: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyClientProfile() async {
    try {
      final token = await TokenStorage.getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/profiles/me/client'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 GET /profiles/me/client - Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ Profile loaded: ${data.keys}');
        return data;
      }
      return {'user': {}, 'profile': {}, 'stats': {}};
    } catch (e) {
      print('❌ getMyClientProfile error: $e');
      return {'user': {}, 'profile': {}, 'stats': {}};
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
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profiles/me/client'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      data.forEach((key, value) {
        if (value != null) {
          if (value is List || value is Map) {
            request.fields[key] = jsonEncode(value);
          } else if (value is DateTime) {
            request.fields[key] = value.toIso8601String();
          } else if (value is bool) {
            request.fields[key] = value.toString();
          } else {
            request.fields[key] = value.toString();
          }
          print('📤 Field: $key = ${request.fields[key]}');
        }
      });

      if (avatarBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            avatarBytes,
            filename:
                avatarFileName ??
                'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        print('📤 Uploading avatar: ${avatarFileName ?? 'avatar.jpg'}');
      }

      if (coverBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'cover',
            coverBytes,
            filename:
                coverFileName ??
                'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        print('📤 Uploading cover: ${coverFileName ?? 'cover.jpg'}');
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      print('📡 PUT /profiles/me/client - Status: ${streamed.statusCode}');
      print(
        '📡 Response: ${body.substring(0, body.length > 200 ? 200 : body.length)}...',
      );

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return jsonDecode(body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${streamed.statusCode}',
          'response': body,
        };
      }
    } catch (e) {
      print('❌ updateClientProfile error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadCompanyLogo(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

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

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return jsonDecode(body);
      }
      return {'success': false, 'message': 'Upload failed'};
    } catch (e) {
      print('uploadCompanyLogo error: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

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
        if (skills != null && skills.isNotEmpty) 'skills': skills,
        if (minRate != null) 'min_rate': '$minRate',
        if (maxRate != null) 'max_rate': '$maxRate',
        if (availability != null) 'availability': availability,
        if (minRating != null) 'min_rating': '$minRating',
        if (location != null && location.isNotEmpty) 'location': location,
      };

      final uri = Uri.parse(
        '$baseUrl/profiles/freelancers/search',
      ).replace(queryParameters: params);

      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) return jsonDecode(res.body);
      return {'freelancers': [], 'total': 0};
    } catch (e) {
      print('searchFreelancers error: $e');
      return {'freelancers': [], 'total': 0};
    }
  }

  static String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return apiMediaUrl(path);
  }
}
