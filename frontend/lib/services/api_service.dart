// services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../utils/constants.dart';
import '../utils/token_storage.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static String? token;
  static String get baseUrl => BASE_URL;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ===== Auth APIs =====
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['user'] != null && data['user']['id'] != null) {
        await TokenStorage.saveUserId(data['user']['id']);
      }

      return data;
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (data['token'] != null) {
        token = data['token'];
        await TokenStorage.saveToken(data['token']);

        if (data['user'] != null && data['user']['id'] != null) {
          await TokenStorage.saveUserId(data['user']['id']);
        }

        if (data['user'] != null && data['user']['role'] != null) {
          await TokenStorage.saveUserRole(data['user']['role']);
        }
      }

      return data;
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<void> logout() async {
    token = null;
    await TokenStorage.clearToken();
    await TokenStorage.clearUserRole();
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  // ===== Client APIs =====

  // Dashboard Stats
  static Future<Map<String, dynamic>> getClientDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/dashboard/stats'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> createProject({
    required String title,
    required String description,
    required double budget,
    required int duration,
    String? category,
    List<String>? skills,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/projects'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'budget': budget,
          'duration': duration,
          'category': category ?? 'other',
          'skills': skills ?? [],
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating project: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProject({
    required int projectId,
    String? title,
    String? description,
    double? budget,
    int? duration,
    String? category,
    List<String>? skills,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/projects/$projectId'),
        headers: headers,
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (budget != null) 'budget': budget,
          if (duration != null) 'duration': duration,
          if (category != null) 'category': category,
          if (skills != null) 'skills': skills,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating project: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/client/projects/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error deleting project: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> completeProject(int projectId) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/projects/$projectId/complete'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error completing project: $e');
      return {'message': 'Connection error'};
    }
  }

  // Proposals
  static Future<List<dynamic>> getProjectProposals(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/projects/$projectId/proposals'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting proposals: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateProposalStatus({
    required int proposalId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/proposals/$proposalId'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating proposal: $e');
      return {'message': 'Connection error'};
    }
  }

  // Contracts
  static Future<Map<String, dynamic>> getProjectContract(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/projects/$projectId/contract'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting contract: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getSuggestedFreelancers(
    int projectId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/client/suggestions/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting freelancer suggestions: $e');
      return {'success': false, 'suggestions': []};
    }
  }

  static Future<List<dynamic>> getMyProjects2() async {
    try {
      print('📥 Fetching my projects...');
      final response = await http.get(
        Uri.parse('$BASE_URL/client/projects'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching my projects: $e');
      return [];
    }
  }

  // ===== Portfolio APIs =====
  static Future<List<dynamic>> getPortfolio(int? userId) async {
    if (userId == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/portfolio/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting portfolio: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createPortfolio({
    required String title,
    required String description,
    required List<String> imagePaths,
    String? projectUrl,
    String? githubUrl,
    List<String>? technologies,
    DateTime? completionDate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/freelancer/portfolio'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = title;
      request.fields['description'] = description;
      if (projectUrl != null) request.fields['project_url'] = projectUrl;
      if (githubUrl != null) request.fields['github_url'] = githubUrl;
      if (technologies != null)
        request.fields['technologies'] = jsonEncode(technologies);
      if (completionDate != null)
        request.fields['completion_date'] = completionDate.toIso8601String();

      for (var i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        return {
          'message': 'Error creating portfolio: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      print('Error creating portfolio: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePortfolio({
    required int portfolioId,
    String? title,
    String? description,
    String? projectUrl,
    String? githubUrl,
    List<String>? technologies,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/freelancer/portfolio/$portfolioId'),
        headers: headers,
        body: jsonEncode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (projectUrl != null) 'project_url': projectUrl,
          if (githubUrl != null) 'github_url': githubUrl,
          if (technologies != null) 'technologies': technologies,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating portfolio: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deletePortfolio(int portfolioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/freelancer/portfolio/$portfolioId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error deleting portfolio: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadCV(
    Uint8List cvBytes,
    String fileName,
  ) async {
    try {
      print('Starting CV upload to: $BASE_URL/freelancer/profile/cv-upload');
      print('Token exists: ${token != null}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/freelancer/profile/cv-upload'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('Authorization header added');
      } else {
        print('Warning: Token is null');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'cv',
          cvBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      print('Sending request...');
      var response = await request.send();
      print('Response status code: ${response.statusCode}');

      var responseData = await response.stream.bytesToString();
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        try {
          return jsonDecode(responseData);
        } catch (e) {
          print('Error parsing JSON: $e');
          return {
            'message': 'Server returned invalid JSON',
            'raw': responseData.substring(0, min(200, responseData.length)),
          };
        }
      } else {
        return {
          'message': 'Server error: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      print('Error uploading CV: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  static Future<Map<String, dynamic>> uploadAvatar(
    Uint8List avatarBytes,
    String fileName,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/freelancer/profile/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          avatarBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      print('Error uploading avatar: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/profile/location'),
        headers: headers,
        body: jsonEncode({'lat': lat, 'lng': lng, 'address': address}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating location: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSuggestedProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/suggested-projects'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting suggested projects: $e');
      return {'projects': [], 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerStats() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/stats'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting freelancer stats: $e');
      return {'stats': {}};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/profile'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting profile: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/freelancer/profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating profile: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getAllProjects() async {
    try {
      print('🔍 Fetching all projects...');
      final response = await http.get(
        Uri.parse('$BASE_URL/projects'),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Projects fetched: ${data.length}');
        return data;
      } else {
        print('❌ Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting projects: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitProposal({
    required int projectId,
    required double price,
    required int deliveryTime,
    required String proposalText,
    List<Map<String, dynamic>>? milestones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/proposals'),
        headers: headers,
        body: jsonEncode({
          'projectId': projectId,
          'price': price,
          'delivery_time': deliveryTime,
          'proposal_text': proposalText,
          'milestones': milestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error submitting proposal: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/messages'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getProjectById(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/projects/$projectId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting project: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getMyProposals() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/proposals'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting my proposals: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMyProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/projects'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting my projects: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAISuggestedProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ai/freelancer/suggestions?limit=10'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting AI suggestions: $e');
      return {'success': false, 'suggestions': []};
    }
  }

  // ===== Contract APIs =====
  static Future<Map<String, dynamic>> getContract(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/contracts/$contractId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting contract: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signContract(int contractId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/sign'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error signing contract: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addContractReview({
    required int contractId,
    required int rating,
    required String review,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/review'),
        headers: headers,
        body: jsonEncode({'rating': rating, 'review': review}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error adding review: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getClientContracts() async {
    try {
      print('📥 Fetching client contracts...');
      final response = await http.get(
        Uri.parse('$BASE_URL/client/contracts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Client contracts fetched: ${data.length}');
        return data;
      }
      print('❌ Failed to fetch contracts: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error getting client contracts: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getFreelancerContracts() async {
    try {
      print('📥 Fetching freelancer contracts...');
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/contracts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Freelancer contracts fetched: ${data.length}');
        return data;
      }
      print('❌ Failed to fetch contracts: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error getting freelancer contracts: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMyContracts(String userRole) async {
    if (userRole == 'client') {
      return getClientContracts();
    } else {
      return getFreelancerContracts();
    }
  }

  static Future<Map<String, dynamic>> requestSignCode(int contractId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/request-code'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> verifyAndSign(
    int contractId,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/contracts/$contractId/verify-and-sign'),
        headers: headers,
        body: jsonEncode({'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ===== Rating APIs =====
  static Future<Map<String, dynamic>> addRating({
    required int contractId,
    required int rating,
    String? comment,
  }) async {
    try {
      print('📝 Adding rating for contract $contractId');
      final response = await http.post(
        Uri.parse('$BASE_URL/ratings'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);
      print('✅ Rating added: $data');
      return data;
    } catch (e) {
      print('❌ Error adding rating: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkCanRate(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ratings/can-rate/$contractId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error checking can rate: $e');
      return {'canRate': false, 'reason': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getContractRatings(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ratings/contract/$contractId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error getting contract ratings: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserRatings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/ratings/user/$userId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error getting user ratings: $e');
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addReminder({
    required int contractId,
    required String title,
    required DateTime dueDate,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/milestones/reminder'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'title': title,
          'dueDate': dueDate.toIso8601String(),
          'description': description,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error adding reminder: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> completeReminder(
    int contractId,
    String reminderId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/milestones/reminder/$contractId/$reminderId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error completing reminder: $e');
      return {'message': 'Connection error'};
    }
  }

  // ===== GitHub APIs =====
  static Future<Map<String, dynamic>> connectGithubRepo({
    required int contractId,
    required String repoUrl,
    String? branch,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/github/connect'),
        headers: headers,
        body: jsonEncode({
          'contractId': contractId,
          'repoUrl': repoUrl,
          'branch': branch,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error connecting GitHub: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<List<dynamic>> getGithubCommits(
    int contractId, {
    String? githubToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/github/commits/$contractId'),
        headers: {
          ...headers,
          if (githubToken != null) 'github_token': githubToken,
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Error getting commits: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getCalendarEvents(int year, int month) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/milestones/calendar?year=$year&month=$month'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Error getting calendar: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getUpcomingEvents(int days) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/milestones/upcoming?days=$days'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Error getting upcoming events: $e');
      return [];
    }
  }

  // ===== Notification APIs =====
  static Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/notifications?limit=$limit&offset=$offset'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting notifications: $e');
      return {'notifications': [], 'total': 0, 'unreadCount': 0};
    }
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/notifications/unread-count'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting unread count: $e');
      return {'unreadCount': 0};
    }
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await http.put(
        Uri.parse('$BASE_URL/notifications/$notificationId/read'),
        headers: headers,
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    try {
      await http.put(
        Uri.parse('$BASE_URL/notifications/read-all'),
        headers: headers,
      );
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  static Future<void> deleteNotification(int notificationId) async {
    try {
      await http.delete(
        Uri.parse('$BASE_URL/notifications/$notificationId'),
        headers: headers,
      );
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // ===== Payment & Wallet APIs =====

  static Future<Map<String, dynamic>> startNegotiation(int proposalId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/proposals/$proposalId/negotiate'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error starting negotiation: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateNegotiation({
    required int proposalId,
    double? price,
    int? deliveryTime,
    List<Map<String, dynamic>>? milestones,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/client/proposals/$proposalId/negotiate'),
        headers: headers,
        body: jsonEncode({
          if (price != null) 'price': price,
          if (deliveryTime != null) 'delivery_time': deliveryTime,
          if (milestones != null) 'milestones': milestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating negotiation: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> acceptProposal({
    required int proposalId,
    double? agreedPrice,
    List<Map<String, dynamic>>? agreedMilestones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/proposals/$proposalId/accept'),
        headers: headers,
        body: jsonEncode({
          if (agreedPrice != null) 'agreedPrice': agreedPrice,
          if (agreedMilestones != null) 'agreedMilestones': agreedMilestones,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error accepting proposal: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required int contractId,
    required String paymentIntentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/contracts/$contractId/confirm-payment'),
        headers: headers,
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error confirming payment: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> releaseMilestone({
    required int contractId,
    required int milestoneIndex,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/client/contracts/$contractId/milestones/$milestoneIndex/release',
        ),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error releasing milestone: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateMilestoneProgress({
    required int contractId,
    required int milestoneIndex,
    required double progress,
    String? status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$BASE_URL/freelancer/contracts/$contractId/milestones/$milestoneIndex/progress',
        ),
        headers: headers,
        body: jsonEncode({
          'progress': progress,
          if (status != null) 'status': status,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error updating milestone progress: $e');
      return {'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/client/wallet'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting wallet: $e');
      return {'wallet': null, 'transactions': []};
    }
  }

  static Future<Map<String, dynamic>> getFreelancerWallet() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/freelancer/wallet'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error getting freelancer wallet: $e');
      return {'wallet': null, 'transactions': []};
    }
  }

  static Future<Map<String, dynamic>> requestWithdrawal(double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/client/wallet/withdraw'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> requestFreelancerWithdrawal(
    double amount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/freelancer/wallet/withdraw'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<String?> createCheckoutSession({
    required int contractId,
    required String paymentIntentId,
  }) async {
    try {
      final url = '$BASE_URL/client/contracts/$contractId/create-checkout';
      print('🔍 URL: $url');
      print('🔍 Headers: $headers');
      print('🔍 paymentIntentId: $paymentIntentId');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      return data['checkoutUrl'];
    } catch (e) {
      print('❌ Error creating checkout session: $e');
      return null;
    }
  }
}
