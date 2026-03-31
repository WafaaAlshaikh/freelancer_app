// lib/services/landing_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/landing_data.dart';
import '../utils/constants.dart';

class LandingService {
  static Future<LandingData> getLandingPage() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/landing'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LandingData.fromJson(data['data']);
      }
      return LandingData.empty();
    } catch (e) {
      print('Error loading landing page: $e');
      return LandingData.empty();
    }
  }
}