// lib/services/skill_test_service.dart
import 'dart:convert';
import 'package:freelancer_platform/screens/skill_tests/skill_tests_screen.dart';
import 'package:http/http.dart' as http;
import '../models/skill_test_model.dart';
import 'api_service.dart';

class SkillTestService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<List<SkillTest>> getAvailableTests({String? skillCategory}) async {
    try {
      final url = '$baseUrl/skill-tests/available${skillCategory != null ? '?skillCategory=$skillCategory' : ''}';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List tests = data['tests'];
        return tests.map((t) => SkillTest.fromJson(t)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting available tests: $e');
      return [];
    }
  }

  static Future<SkillTest?> getTest(int testId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/skill-tests/$testId'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SkillTest.fromJson(data['test']);
      }
      return null;
    } catch (e) {
      print('Error getting test: $e');
      return null;
    }
  }

  // lib/services/skill_test_service.dart
static Future<Map<String, dynamic>> startTest(int testId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/skill-tests/$testId/start'),
      headers: ApiService.headers,
    );

    print('Start test response status: ${response.statusCode}');
    print('Start test response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // التحقق من وجود userTestId في الاستجابة
      if (data['success'] == true && data['userTestId'] != null) {
        return {
          'success': true,
          'userTestId': data['userTestId'],
          'testId': data['testId'],
          'startedAt': data['startedAt'],
        };
      } else {
        print('Invalid response format: $data');
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid response from server',
        };
      }
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to start test',
      };
    }
  } catch (e) {
    print('Error starting test: $e');
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}

  static Future<Map<String, dynamic>> submitTest(int userTestId, List<Map<String, dynamic>> answers) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/skill-tests/submit/$userTestId'),
        headers: ApiService.headers,
        body: jsonEncode({'answers': answers}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print('Error submitting test: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<TestResult>> getUserTestResults() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/skill-tests/results'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];
        return results.map((r) => TestResult.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting test results: $e');
      return [];
    }
  }

  static Future<TestStats?> getUserTestStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/skill-tests/stats'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TestStats.fromJson(data['stats']);
      }
      return null;
    } catch (e) {
      print('Error getting test stats: $e');
      return null;
    }
  }
}