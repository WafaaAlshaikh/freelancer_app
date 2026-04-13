//lib\constants.dart
const String BASE_URL = "http://localhost:5001/api";

String apiMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final origin = Uri.parse(BASE_URL).origin;
  if (path.startsWith('/')) return '$origin$path';
  return '$origin/$path';
}
