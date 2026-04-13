import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftLocalStorage {
  static const _projectDraftKey = 'draft_project_create_v1';
  static const _proposalDraftsKey = 'draft_proposals_by_project_v1';
  static const _publishReminderSnoozeKey = 'draft_publish_reminder_snooze_ms';

  static Future<SharedPreferences> get _p async =>
      SharedPreferences.getInstance();

  static Future<Map<String, dynamic>?> getProjectCreateDraft() async {
    final prefs = await _p;
    final raw = prefs.getString(_projectDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProjectCreateDraft(Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    final prefs = await _p;
    await prefs.setString(_projectDraftKey, jsonEncode(data));
  }

  static Future<void> clearProjectCreateDraft() async {
    final prefs = await _p;
    await prefs.remove(_projectDraftKey);
  }

  static bool isMeaningfulProjectDraft(Map<String, dynamic>? d) {
    if (d == null) return false;
    final t = (d['title'] ?? '').toString().trim();
    final desc = (d['description'] ?? '').toString().trim();
    if (t.length >= 3 || desc.length >= 25) return true;
    final skills = d['skills'];
    if (skills is List && skills.isNotEmpty) return true;
    return false;
  }

  static Future<bool> shouldShowPublishReminder() async {
    final prefs = await _p;
    final snoozeUntil = prefs.getInt(_publishReminderSnoozeKey) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < snoozeUntil) return false;
    final d = await getProjectCreateDraft();
    return isMeaningfulProjectDraft(d);
  }

  static Future<void> snoozePublishReminder({
    Duration duration = const Duration(hours: 24),
  }) async {
    final prefs = await _p;
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setInt(_publishReminderSnoozeKey, until);
  }

  static Future<void> clearPublishReminderSnooze() async {
    final prefs = await _p;
    await prefs.remove(_publishReminderSnoozeKey);
  }

  static Future<Map<String, dynamic>?> getProposalDraft(int projectId) async {
    final prefs = await _p;
    final raw = prefs.getString(_proposalDraftsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final all = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final key = projectId.toString();
      if (!all.containsKey(key)) return null;
      final one = all[key];
      if (one is Map) return Map<String, dynamic>.from(one);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProposalDraft(
    int projectId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    final prefs = await _p;
    Map<String, dynamic> all = {};
    final raw = prefs.getString(_proposalDraftsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        all = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    all[projectId.toString()] = data;
    await prefs.setString(_proposalDraftsKey, jsonEncode(all));
  }

  static Future<void> clearProposalDraft(int projectId) async {
    final prefs = await _p;
    final raw = prefs.getString(_proposalDraftsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final all = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      all.remove(projectId.toString());
      if (all.isEmpty) {
        await prefs.remove(_proposalDraftsKey);
      } else {
        await prefs.setString(_proposalDraftsKey, jsonEncode(all));
      }
    } catch (_) {}
  }

  static List<Map<String, dynamic>> milestonesFromJson(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }
}
