import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';
import 'api_service.dart';

class AdService {
  static String get baseUrl => BASE_URL;

  static Future<List<Map<String, dynamic>>> getActiveAds({
    required String placement,
    int limit = 3,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/ads/active?placement=$placement&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['ads'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error loading ads: $e');
      return [];
    }
  }

  static Future<String?> trackClick(int campaignId) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$campaignId/click'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Error tracking click: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyCampaigns({
    String? status,
    int page = 1,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      String url = '$baseUrl/ads/my-campaigns?page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['campaigns'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting campaigns: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCampaign(
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ads/campaigns'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> activateCampaign(int campaignId) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/ads/$campaignId/activate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error activating campaign: $e');
      return false;
    }
  }

  static Future<bool> pauseCampaign(int campaignId) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/ads/$campaignId/pause'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error pausing campaign: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createPaymentSession(
    int campaignId, {
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$campaignId/create-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'successUrl': successUrl, 'cancelUrl': cancelUrl}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> payWithWallet(int campaignId) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$campaignId/pay-with-wallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatus(int campaignId) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/ads/$campaignId/payment-status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getRevenueStats() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/ads/admin/revenue-stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'stats': {}};
    }
  }

  static Future<bool> recordManualPayment(
    int campaignId, {
    required double amount,
    required String reference,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ads/admin/$campaignId/record-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': amount, 'reference': reference}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error recording manual payment: $e');
      return false;
    }
  }

  static double calculateEstimatedCost({
    required String pricingModel,
    required double budget,
    double? cpc,
    double? cpm,
  }) {
    switch (pricingModel) {
      case 'cpc':
        return budget;
      case 'cpm':
        return budget;
      case 'flat':
        return budget;
      default:
        return budget;
    }
  }

  static double calculatePlatformCommission(double amount) {
    return amount * 0.2;
  }
}
