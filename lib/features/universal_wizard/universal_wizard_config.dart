// =============================================================================
// v1.3: 9대 카테고리 유니버설 4단계 위저드 설정
// 디자인 헌법: 곡률 28.0px, 로얄 네이비 #1E293B
// =============================================================================

import 'package:flutter/material.dart';

/// 3단계 시각적 가이드 유형 (카테고리별)
enum VisualGuideType {
  /// 뷰티/수리: 원하는 스타일 또는 고장 부위 사진 5장 업로드
  photoUpload,
  /// 배달: 지도 위 출발/도착지 찍기
  mapPick,
  /// 과외 등: 학습 목표·희망 스케줄 텍스트
  textFields,
  /// 기본: 증상/요구 체크 + 메모
  symptomAndNote,
}

/// 2단계 선택 유형
enum Step2ChoiceType {
  /// 규모 S/M/L
  scaleSML,
  /// 대상 (예: 초등/중등/고등)
  targetAudience,
  /// 단일 선택 리스트
  singleList,
  /// 없음 (건너뛰기)
  none,
}

/// 카테고리별 위저드 설정 (1: 세부유형, 2: 규모/대상, 3: 시각적 가이드, 4: 확정)
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
  /// 1단계: 세부 서비스 유형 (예: 수학/영어/라오어)
  final List<MapEntry<String, String>> step1SubTypes;
  final Step2ChoiceType step2ChoiceType;
  final List<String> step2Labels;
  final List<String> step2Ids;
  final VisualGuideType visualGuideType;
  final int photoSlotCount;

  static const Color royalNavy = Color(0xFF1E293B);
}

/// 9대 카테고리 설정 맵 (i18n 키 또는 로컬 라벨)
const Map<String, UniversalWizardConfig> kUniversalWizardConfigs = {
  'expert_repair': UniversalWizardConfig(
    categoryKey: 'expert_repair',
    step1SubTypes: [
      MapEntry('ac', 'service_ac'),
      MapEntry('household', 'service_household'),
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
  'expert_cleaning': UniversalWizardConfig(
    categoryKey: 'expert_cleaning',
    step1SubTypes: [
      MapEntry('move_in', 'sub_cleaning_move_in'),
      MapEntry('commercial', 'sub_cleaning_commercial'),
      MapEntry('appliance', 'sub_cleaning_appliance'),
      MapEntry('bedding', 'sub_cleaning_bedding'),
      MapEntry('regular', 'sub_cleaning_regular_visit'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['cleaning_size_s', 'cleaning_size_m', 'cleaning_size_l'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_security': UniversalWizardConfig(
    categoryKey: 'expert_security',
    step1SubTypes: [
      MapEntry('building', 'sub_security_building'),
      MapEntry('site', 'sub_security_site'),
      MapEntry('vip', 'sub_security_vip'),
      MapEntry('event', 'sub_security_event'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['wizard_duration_1d', 'wizard_duration_1w', 'wizard_duration_1m', 'wizard_duration_long'],
    step2Ids: ['1d', '1w', '1m', 'long'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 3,
  ),
  'expert_delivery': UniversalWizardConfig(
    categoryKey: 'expert_delivery',
    step1SubTypes: [
      MapEntry('food', 'sub_delivery_food'),
      MapEntry('cargo', 'sub_delivery_cargo'),
      MapEntry('mart', 'sub_delivery_mart'),
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
      MapEntry('general', 'sub_beauty_general'),
      MapEntry('care', 'wizard_beauty_sub_care'),
      MapEntry('nail_makeup', 'wizard_beauty_sub_nail_makeup'),
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
      MapEntry('lang', 'sub_tutor_lang'),
      MapEntry('math_sci', 'wizard_tutor_sub_math_sci'),
      MapEntry('it', 'wizard_tutor_sub_it_computer'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.targetAudience,
    step2Labels: ['wizard_level_elem', 'wizard_level_mid', 'wizard_level_high', 'wizard_level_adult'],
    step2Ids: ['elem', 'mid', 'high', 'adult'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_photo': UniversalWizardConfig(
    categoryKey: 'expert_photo',
    step1SubTypes: [
      MapEntry('wedding', 'wizard_photo_sub_wedding'),
      MapEntry('snap', 'wizard_photo_sub_snap'),
      MapEntry('product_ad', 'wizard_photo_sub_product_ad'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['wizard_photo_duration_half_day', 'wizard_duration_1d', 'wizard_photo_duration_2d_plus'],
    step2Ids: ['half', '1d', '2d'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_event': UniversalWizardConfig(
    categoryKey: 'expert_event',
    step1SubTypes: [
      MapEntry('party_planning', 'wizard_event_sub_party_planning'),
      MapEntry('sound_light_rental', 'wizard_event_sub_sound_light_rental'),
      MapEntry('helper', 'wizard_event_sub_helper'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['wizard_event_scale_s', 'wizard_event_scale_m', 'wizard_event_scale_l'],
    step2Ids: ['s', 'm', 'l'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 3,
  ),
  'expert_garden': UniversalWizardConfig(
    categoryKey: 'expert_garden',
    step1SubTypes: [
      MapEntry('lawn', 'sub_garden_lawn'),
      MapEntry('landscape', 'wizard_garden_sub_landscape'),
      MapEntry('tree_trim', 'sub_garden_trim'),
      MapEntry('other', 'symptom_other'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['S', 'M', 'L'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
};
