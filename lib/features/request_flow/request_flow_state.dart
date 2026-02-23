// =============================================================================
// LT-09 Feature: request_flow — 질문지 로컬 상태 (70% 동선)
// Local State Persistence. Handover: 한/영 주석.
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

/// 질문지 작성 상태. 앱 재시작 후에도 유지. / Form state persisted across restarts.
class RequestFlowState {
  RequestFlowState({
    this.category = '',
    this.selectedSymptomIds = const [],
    this.location = '',
    this.wishedTime = '',
    this.photoPath,
    this.extraNote = '',
  });

  final String category;
  final List<String> selectedSymptomIds;
  final String location;
  final String wishedTime;
  final String? photoPath;
  final String extraNote;

  static const String _keyPrefix = 'laotrust_request_flow_';

  RequestFlowState copyWith({
    String? category,
    List<String>? selectedSymptomIds,
    String? location,
    String? wishedTime,
    String? photoPath,
    String? extraNote,
  }) {
    return RequestFlowState(
      category: category ?? this.category,
      selectedSymptomIds: selectedSymptomIds ?? this.selectedSymptomIds,
      location: location ?? this.location,
      wishedTime: wishedTime ?? this.wishedTime,
      photoPath: photoPath ?? this.photoPath,
      extraNote: extraNote ?? this.extraNote,
    );
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPrefix + 'symptoms', selectedSymptomIds);
    await prefs.setString(_keyPrefix + 'location', location);
    await prefs.setString(_keyPrefix + 'wishedTime', wishedTime);
    await prefs.setString(_keyPrefix + 'extraNote', extraNote);
    if (photoPath != null) {
      await prefs.setString(_keyPrefix + 'photoPath', photoPath!);
    }
  }

  static Future<RequestFlowState> restore({String category = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    return RequestFlowState(
      category: category,
      selectedSymptomIds: prefs.getStringList(_keyPrefix + 'symptoms') ?? [],
      location: prefs.getString(_keyPrefix + 'location') ?? '',
      wishedTime: prefs.getString(_keyPrefix + 'wishedTime') ?? '',
      photoPath: prefs.getString(_keyPrefix + 'photoPath'),
      extraNote: prefs.getString(_keyPrefix + 'extraNote') ?? '',
    );
  }
}
