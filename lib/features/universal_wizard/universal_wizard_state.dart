// =============================================================================
// universal_wizard_state.dart
// v5.1: step3ServiceMode 추가 - flexible 모드 선택 결과 저장
// =============================================================================

/// flexible 모드에서 사용자가 선택한 서비스 방식
enum ServiceModeChoice {
  remote, // 원격/온라인
  visit, // 방문 (전문가가 고객에게)
  goToShop, // 고객이 샵/정비소로 방문
}

const Object _kUnsetServiceMode = Object();

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
    this.step3ServiceMode,
  });

  final String categoryKey;
  final String step1SubTypeId;
  final String step1SubTypeLabel;
  final String step2SelectedId;
  final String step2SelectedLabel;
  final List<String> step3PhotoPaths;

  /// 현장형/이동형: 위치 랜드마크 (GPS 보조)
  final String step3Landmark;

  /// 이동형: 출발지 랜드마크
  final String step3MovingFromLandmark;

  /// 이동형: 도착지 랜드마크
  final String step3MovingToLandmark;

  final double? step3Lat;
  final double? step3Lng;

  /// 일정 선택
  final String preferredDateStr;
  final String preferredTimeStr;
  final bool scheduleIsUrgent;

  final String step3LearningGoal;
  final String step3Schedule;
  final List<String> step3SymptomIds;
  final String step3ExtraNote;

  /// flexible 모드 선택 결과 (비즈니스/과외/미용/차량)
  /// null = 아직 선택 안 함
  final ServiceModeChoice? step3ServiceMode;

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
    Object? step3ServiceMode = _kUnsetServiceMode,
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
      step3ServiceMode: identical(step3ServiceMode, _kUnsetServiceMode)
          ? this.step3ServiceMode
          : step3ServiceMode as ServiceModeChoice?,
    );
  }
}
