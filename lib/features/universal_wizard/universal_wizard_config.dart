// =============================================================================
// v5.0: 9대 카테고리 유니버설 4단계 위저드 설정 (집도 최종본)
// D1 유형 → D2 전문 질문 → D3 사진·위치·일시 → D4 요약·신청
// =============================================================================

import 'package:flutter/material.dart';

/// 3단계 시각적 가이드 유형 (레거시 필드 — v5에서는 D3가 카테고리 공통)
enum VisualGuideType {
  photoUpload,
  mapPick,
  textFields,
  symptomAndNote,
}

/// 2단계 선택 유형 (레거시)
enum Step2ChoiceType {
  scaleSML,
  targetAudience,
  singleList,
  none,
}

/// 카테고리별 위저드 설정 (1: 세부유형, 2: 규모/대상, 3·4: 공통 로직에서 처리)
class UniversalWizardConfig {
  const UniversalWizardConfig({
    required this.categoryKey,
    required this.step1SubTypes,
    required this.step2ChoiceType,
    this.step2Labels = const [],
    this.step2Ids = const [],
    required this.visualGuideType,
    this.photoSlotCount = 5,
  });

  final String categoryKey;
  final List<MapEntry<String, String>> step1SubTypes;
  final Step2ChoiceType step2ChoiceType;
  final List<String> step2Labels;
  final List<String> step2Ids;
  final VisualGuideType visualGuideType;
  final int photoSlotCount;

  static const Color royalNavy = Color(0xFF1E293B);
}

/// 9대 카테고리 (홈 그리드 키와 1:1)
const Map<String, UniversalWizardConfig> kUniversalWizardConfigs = {
  'expert_cleaning': UniversalWizardConfig(
    categoryKey: 'expert_cleaning',
    step1SubTypes: [
      MapEntry('move_in', 'sub_cleaning_move_in'),
      MapEntry('house_cleaning', 'sub_cleaning_house'),
      MapEntry('restaurant_cafe', 'sub_cleaning_restaurant_cafe'),
      MapEntry('regular_visit', 'sub_cleaning_regular_visit'),
      MapEntry('bedding', 'sub_cleaning_bedding'),
      MapEntry('appliance', 'sub_cleaning_appliance'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['cleaning_size_s', 'cleaning_size_m', 'cleaning_size_l'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_moving': UniversalWizardConfig(
    categoryKey: 'expert_moving',
    step1SubTypes: [
      MapEntry('small', 'sub_moving_small'),
      MapEntry('home', 'sub_moving_home'),
      MapEntry('cargo', 'sub_moving_cargo'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_repair': UniversalWizardConfig(
    categoryKey: 'expert_repair',
    step1SubTypes: [
      MapEntry('appliance', 'sub_repair_appliance'),
      MapEntry('electric', 'service_electric'),
      MapEntry('plumbing', 'service_plumbing'),
      MapEntry('roof', 'wizard_repair_sub_roof_paint'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['cleaning_size_s', 'cleaning_size_m', 'cleaning_size_l'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_interior': UniversalWizardConfig(
    categoryKey: 'expert_interior',
    step1SubTypes: [
      MapEntry('wallpaper', 'sub_interior_wallpaper'),
      MapEntry('flooring', 'sub_interior_flooring'),
      MapEntry('painting', 'sub_interior_painting'),
      MapEntry('bathroom', 'sub_interior_bathroom'),
      MapEntry('kitchen', 'sub_interior_kitchen'),
      MapEntry('remodel', 'sub_interior_remodel'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_business': UniversalWizardConfig(
    categoryKey: 'expert_business',
    step1SubTypes: [
      MapEntry('translate_docs', 'sub_business_translate'),
      MapEntry('interpret', 'sub_business_interpret'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_beauty': UniversalWizardConfig(
    categoryKey: 'expert_beauty',
    step1SubTypes: [
      MapEntry('massage', 'sub_beauty_massage'),
      MapEntry('nail', 'sub_beauty_nail'),
      MapEntry('hair', 'sub_beauty_hair'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_tutoring': UniversalWizardConfig(
    categoryKey: 'expert_tutoring',
    step1SubTypes: [
      MapEntry('lang_en', 'sub_tutor_lang_en'),
      MapEntry('lang_ko', 'sub_tutor_lang_ko'),
      MapEntry('lang_lo', 'sub_tutor_lang_lo'),
      MapEntry('lang_zh', 'sub_tutor_lang_zh'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.targetAudience,
    step2Labels: ['wizard_level_elem', 'wizard_level_mid', 'wizard_level_high', 'wizard_level_adult'],
    step2Ids: ['elem', 'mid', 'high', 'adult'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_events': UniversalWizardConfig(
    categoryKey: 'expert_events',
    step1SubTypes: [
      MapEntry('party', 'sub_events_party'),
      MapEntry('photo_video', 'sub_events_photo_video'),
      MapEntry('catering', 'sub_events_catering'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['wizard_event_scale_s', 'wizard_event_scale_m', 'wizard_event_scale_l'],
    step2Ids: ['s', 'm', 'l'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_vehicle': UniversalWizardConfig(
    categoryKey: 'expert_vehicle',
    step1SubTypes: [
      MapEntry('repair', 'sub_vehicle_repair'),
      MapEntry('rental', 'sub_vehicle_rental'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
};
