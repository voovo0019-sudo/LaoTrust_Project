// =============================================================================
// v1.3: 유니버설 4단계 위저드 상태 (9대 카테고리 공통)
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
    this.step3OriginLat,
    this.step3OriginLng,
    this.step3DestLat,
    this.step3DestLng,
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
  final double? step3OriginLat;
  final double? step3OriginLng;
  final double? step3DestLat;
  final double? step3DestLng;
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
    double? step3OriginLat,
    double? step3OriginLng,
    double? step3DestLat,
    double? step3DestLng,
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
      step3OriginLat: step3OriginLat ?? this.step3OriginLat,
      step3OriginLng: step3OriginLng ?? this.step3OriginLng,
      step3DestLat: step3DestLat ?? this.step3DestLat,
      step3DestLng: step3DestLng ?? this.step3DestLng,
      step3LearningGoal: step3LearningGoal ?? this.step3LearningGoal,
      step3Schedule: step3Schedule ?? this.step3Schedule,
      step3SymptomIds: step3SymptomIds ?? this.step3SymptomIds,
      step3ExtraNote: step3ExtraNote ?? this.step3ExtraNote,
    );
  }
}
