//lib\constants.dart
const String BASE_URL = "https://freelancer-backend-poh2.onrender.com/api";

String apiMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final origin = Uri.parse(BASE_URL).origin;
  if (path.startsWith('/')) return '$origin$path';
  return '$origin/$path';
}
