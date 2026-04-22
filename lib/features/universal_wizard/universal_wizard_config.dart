// =============================================================================
// universal_wizard_config.dart
// v5.1: Step3LocationMode 추가 - 글로벌 구조 확장
// =============================================================================

import 'package:flutter/material.dart';

/// Step3 위치/방문 방식 모드
enum Step3LocationMode {
  onsite, // 현장형: 청소/수리/인테리어/이벤트 - GPS/주소 필수
  routing, // 이동형: 이사 - 출발지+도착지
  flexible, // 선택형: 비즈니스/과외/미용/차량 - 원격or방문 선택
}

/// 3단계 시각 가이드 타입
enum VisualGuideType {
  photoUpload,
  mapPick,
  textFields,
  symptomAndNote,
}

/// 2단계 선택 타입
enum Step2ChoiceType {
  scaleSML,
  targetAudience,
  singleList,
  none,
}

/// 위저드 설정 클래스
class UniversalWizardConfig {
  const UniversalWizardConfig({
    required this.categoryKey,
    required this.step1SubTypes,
    required this.step2ChoiceType,
    this.step2Labels = const [],
    this.step2Ids = const [],
    required this.visualGuideType,
    this.photoSlotCount = 5,
    required this.step3Mode,
  });

  final String categoryKey;
  final List<MapEntry<String, String>> step1SubTypes;
  final Step2ChoiceType step2ChoiceType;
  final List<String> step2Labels;
  final List<String> step2Ids;
  final VisualGuideType visualGuideType;
  final int photoSlotCount;
  final Step3LocationMode step3Mode;

  static const Color royalNavy = Color(0xFF1E293B);
}

/// 9개 카테고리 설정
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
    step3Mode: Step3LocationMode.onsite,
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
    step3Mode: Step3LocationMode.routing,
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
    step3Mode: Step3LocationMode.onsite,
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
    step3Mode: Step3LocationMode.onsite,
  ),
  'expert_business': UniversalWizardConfig(
    categoryKey: 'expert_business',
    step1SubTypes: [
      MapEntry('translate_docs', 'sub_business_translate'),
      MapEntry('interpret', 'sub_business_interpret'),
      MapEntry('visa_permit', 'sub_business_visa'),
      MapEntry('company_setup', 'sub_business_company_setup'),
      MapEntry('accounting', 'sub_business_accounting'),
      MapEntry('legal_doc', 'sub_business_legal'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 3,
    step3Mode: Step3LocationMode.flexible,
  ),
  'expert_beauty': UniversalWizardConfig(
    categoryKey: 'expert_beauty',
    step1SubTypes: [
      MapEntry('massage_traditional', 'sub_beauty_massage_traditional'),
      MapEntry('massage_aroma', 'sub_beauty_massage_aroma'),
      MapEntry('nail', 'sub_beauty_nail'),
      MapEntry('hair', 'sub_beauty_hair'),
      MapEntry('makeup', 'sub_beauty_makeup'),
      MapEntry('waxing', 'sub_beauty_waxing'),
      MapEntry('skin_care', 'sub_beauty_skin_care'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 3,
    step3Mode: Step3LocationMode.flexible,
  ),
  'expert_tutoring': UniversalWizardConfig(
    categoryKey: 'expert_tutoring',
    step1SubTypes: [
      MapEntry('lang_en', 'sub_tutor_lang_en'),
      MapEntry('lang_ko', 'sub_tutor_lang_ko'),
      MapEntry('lang_lo', 'sub_tutor_lang_lo'),
      MapEntry('lang_zh', 'sub_tutor_lang_zh'),
      MapEntry('math_science', 'sub_tutor_math_science'),
      MapEntry('music', 'sub_tutor_music'),
      MapEntry('martial_arts', 'sub_tutor_martial_arts'),
      MapEntry('cooking', 'sub_tutor_cooking'),
      MapEntry('computer', 'sub_tutor_computer'),
      MapEntry('art', 'sub_tutor_art'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.targetAudience,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 3,
    step3Mode: Step3LocationMode.flexible,
  ),
  'expert_events': UniversalWizardConfig(
    categoryKey: 'expert_events',
    step1SubTypes: [
      MapEntry('wedding_photo', 'sub_events_wedding_photo'),
      MapEntry('portrait', 'sub_events_portrait'),
      MapEntry('commercial', 'sub_events_commercial'),
      MapEntry('drone', 'sub_events_drone'),
      MapEntry('party', 'sub_events_party'),
      MapEntry('catering', 'sub_events_catering'),
      MapEntry('mc_dj', 'sub_events_mc_dj'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
    step3Mode: Step3LocationMode.onsite,
  ),
  'expert_vehicle': UniversalWizardConfig(
    categoryKey: 'expert_vehicle',
    step1SubTypes: [
      MapEntry('car_repair', 'sub_vehicle_car_repair'),
      MapEntry('moto_repair', 'sub_vehicle_moto_repair'),
      MapEntry('car_rental', 'sub_vehicle_car_rental'),
      MapEntry('moto_rental', 'sub_vehicle_moto_rental'),
      MapEntry('tire_battery', 'sub_vehicle_tire_battery'),
      MapEntry('carwash', 'sub_vehicle_carwash'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
    step3Mode: Step3LocationMode.flexible,
  ),
};
