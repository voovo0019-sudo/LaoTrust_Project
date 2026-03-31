// =============================================================================
// v5.0: 유니버설 4단계 위저드 상태 — D3 현장 정보(사진·위치·일시) + 요약/신청
// =============================================================================

/// 위저드 전체 상태
class UniversalWizardState {
  UniversalWizardState({
    this.categoryKey = '',
    this.step1SubTypeId = '',
    this.step1SubTypeLabel = '',
    this.step2SelectedId = '',
    this.step2SelectedLabel = '',
    this.step3PhotoPaths = const [],
    this.step3Landmark = '',
    this.step3MovingFromLandmark = '',
    this.step3MovingToLandmark = '',
    this.step3Lat,
    this.step3Lng,
    this.preferredDateStr = '',
    this.preferredTimeStr = '',
    this.scheduleIsUrgent = false,
    this.step3LearningGoal = '',
    this.step3Schedule = '',
    this.step3SymptomIds = const [],
    this.step3ExtraNote = '',
  });

  final String categoryKey;
  final String step1SubTypeId;
  final String step1SubTypeLabel;
  final String step2SelectedId;
  final String step2SelectedLabel;
  final List<String> step3PhotoPaths;

  /// D3: 랜드마크/주소 설명 (GPS 미사용 시 필수)
  final String step3Landmark;
  /// 이사: 출발지 설명
  final String step3MovingFromLandmark;
  /// 이사: 도착지 설명
  final String step3MovingToLandmark;
  final double? step3Lat;
  final double? step3Lng;

  /// D3: 희망 일시 (라오스 현지 기준 입력)
  final String preferredDateStr;
  final String preferredTimeStr;
  final bool scheduleIsUrgent;

  final String step3LearningGoal;
  final String step3Schedule;
  final List<String> step3SymptomIds;
  final String step3ExtraNote;

  UniversalWizardState copyWith({
    String? categoryKey,
    String? step1SubTypeId,
    String? step1SubTypeLabel,
    String? step2SelectedId,
    String? step2SelectedLabel,
    List<String>? step3PhotoPaths,
    String? step3Landmark,
    String? step3MovingFromLandmark,
    String? step3MovingToLandmark,
    double? step3Lat,
    double? step3Lng,
    String? preferredDateStr,
    String? preferredTimeStr,
    bool? scheduleIsUrgent,
    String? step3LearningGoal,
    String? step3Schedule,
    List<String>? step3SymptomIds,
    String? step3ExtraNote,
  }) {
    return UniversalWizardState(
      categoryKey: categoryKey ?? this.categoryKey,
      step1SubTypeId: step1SubTypeId ?? this.step1SubTypeId,
      step1SubTypeLabel: step1SubTypeLabel ?? this.step1SubTypeLabel,
      step2SelectedId: step2SelectedId ?? this.step2SelectedId,
      step2SelectedLabel: step2SelectedLabel ?? this.step2SelectedLabel,
      step3PhotoPaths: step3PhotoPaths ?? this.step3PhotoPaths,
      step3Landmark: step3Landmark ?? this.step3Landmark,
      step3MovingFromLandmark: step3MovingFromLandmark ?? this.step3MovingFromLandmark,
      step3MovingToLandmark: step3MovingToLandmark ?? this.step3MovingToLandmark,
      step3Lat: step3Lat ?? this.step3Lat,
      step3Lng: step3Lng ?? this.step3Lng,
      preferredDateStr: preferredDateStr ?? this.preferredDateStr,
      preferredTimeStr: preferredTimeStr ?? this.preferredTimeStr,
      scheduleIsUrgent: scheduleIsUrgent ?? this.scheduleIsUrgent,
      step3LearningGoal: step3LearningGoal ?? this.step3LearningGoal,
      step3Schedule: step3Schedule ?? this.step3Schedule,
      step3SymptomIds: step3SymptomIds ?? this.step3SymptomIds,
      step3ExtraNote: step3ExtraNote ?? this.step3ExtraNote,
    );
  }
}
