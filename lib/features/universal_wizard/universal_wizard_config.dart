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
      MapEntry('ac', '에어컨'),
      MapEntry('household', '가전'),
      MapEntry('electric', '전기'),
      MapEntry('plumbing', '배관'),
      MapEntry('roof', '페인트 및 지붕 보수'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['S (30㎡↓)', 'M (30-60㎡)', 'L (60㎡↑)'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_cleaning': UniversalWizardConfig(
    categoryKey: 'expert_cleaning',
    step1SubTypes: [
      MapEntry('move_in', '이사/입주'),
      MapEntry('commercial', '상업공간'),
      MapEntry('appliance', '가전청소'),
      MapEntry('bedding', '침구세척'),
      MapEntry('regular', '정기 방문(주/월)'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['S (30㎡↓)', 'M (30-60㎡)', 'L (60㎡↑)'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_security': UniversalWizardConfig(
    categoryKey: 'expert_security',
    step1SubTypes: [
      MapEntry('building', '건물·상가(장기)'),
      MapEntry('site', '공사장·창고'),
      MapEntry('vip', 'VIP 경호'),
      MapEntry('event', '단기 행사 보안'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['1일', '1주', '1개월', '장기'],
    step2Ids: ['1d', '1w', '1m', 'long'],
    visualGuideType: VisualGuideType.symptomAndNote,
    photoSlotCount: 3,
  ),
  'expert_delivery': UniversalWizardConfig(
    categoryKey: 'expert_delivery',
    step1SubTypes: [
      MapEntry('food', '음식 배달'),
      MapEntry('cargo', '소형 화물'),
      MapEntry('mart', '마트 장보기 대행'),
    ],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.mapPick,
    photoSlotCount: 0,
  ),
  'expert_beauty': UniversalWizardConfig(
    categoryKey: 'expert_beauty',
    step1SubTypes: [MapEntry('general', '일반 뷰티/헬스')],
    step2ChoiceType: Step2ChoiceType.none,
    step2Labels: [],
    step2Ids: [],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_tutoring': UniversalWizardConfig(
    categoryKey: 'expert_tutoring',
    step1SubTypes: [
      MapEntry('math', '수학'),
      MapEntry('english', '영어'),
      MapEntry('lao', '라오어'),
      MapEntry('other', '기타'),
    ],
    step2ChoiceType: Step2ChoiceType.targetAudience,
    step2Labels: ['초등', '중등', '고등', '성인'],
    step2Ids: ['elem', 'mid', 'high', 'adult'],
    visualGuideType: VisualGuideType.textFields,
    photoSlotCount: 0,
  ),
  'expert_photo': UniversalWizardConfig(
    categoryKey: 'expert_photo',
    step1SubTypes: [
      MapEntry('studio', '스튜디오'),
      MapEntry('event', '이벤트 촬영'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['반나절', '1일', '2일 이상'],
    step2Ids: ['half', '1d', '2d'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
  'expert_event': UniversalWizardConfig(
    categoryKey: 'expert_event',
    step1SubTypes: [
      MapEntry('catering', '케이터링'),
      MapEntry('deco', '장식/데코'),
      MapEntry('mc', '사회자'),
      MapEntry('sound', '음향 장비 렌탈'),
    ],
    step2ChoiceType: Step2ChoiceType.singleList,
    step2Labels: ['소규모', '중규모', '대규모'],
    step2Ids: ['s', 'm', 'l'],
    visualGuideType: VisualGuideType.symptomAndNote,
    photoSlotCount: 3,
  ),
  'expert_garden': UniversalWizardConfig(
    categoryKey: 'expert_garden',
    step1SubTypes: [
      MapEntry('lawn', '잔디 깎기'),
      MapEntry('trim', '가지치기'),
      MapEntry('pest', '해충 및 살충 방역'),
    ],
    step2ChoiceType: Step2ChoiceType.scaleSML,
    step2Labels: ['S', 'M', 'L'],
    step2Ids: ['S', 'M', 'L'],
    visualGuideType: VisualGuideType.photoUpload,
    photoSlotCount: 5,
  ),
};
