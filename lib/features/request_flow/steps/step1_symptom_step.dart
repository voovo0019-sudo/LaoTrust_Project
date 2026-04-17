// =============================================================================
// Step 1: 가전 종류 선택(아이콘 카드) → 증상 선택 (2단계 구조)
// 글로벌 Triple-Map 철학 준수. 시연용 고급 UI.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import '../request_flow_state.dart';

class Step1SymptomStep extends StatelessWidget {
  const Step1SymptomStep({
    super.key,
    required this.state,
    required this.onChanged,
  });
  final RequestFlowState state;
  final ValueChanged<RequestFlowState> onChanged;

  // 가전 종류 목록 (아이콘 + 번역키)
  static const List<_ApplianceItem> _appliances = [
    _ApplianceItem('ac',             'appliance_ac',            '❄️'),
    _ApplianceItem('fridge',         'appliance_fridge',        '🧊'),
    _ApplianceItem('washer',         'appliance_washer',        '🫧'),
    _ApplianceItem('tv',             'appliance_tv',            '📺'),
    _ApplianceItem('water_purifier', 'appliance_water_purifier','💧'),
    _ApplianceItem('fan',            'appliance_fan',           '🌀'),
    _ApplianceItem('rice_cooker',    'appliance_rice_cooker',   '🍚'),
    _ApplianceItem('generator',      'appliance_generator',     '⚡'),
    _ApplianceItem('other',          'appliance_other',         '🔧'),
  ];

  // 가전별 증상 목록
  static const Map<String, List<_SymptomItem>> _symptomsByAppliance = {
    'ac': [
      _SymptomItem('no_cold',    'symptom_ac_no_cold_air'),
      _SymptomItem('noise',      'symptom_ac_noise'),
      _SymptomItem('water_leak', 'symptom_ac_water_sound'),
      _SymptomItem('not_cool',   'symptom_ac_not_cool'),
      _SymptomItem('other',      'symptom_other'),
    ],
    'fridge': [
      _SymptomItem('no_cool', 'symptom_fridge_no_cool'),
      _SymptomItem('noise',   'symptom_fridge_noise'),
      _SymptomItem('door',    'symptom_fridge_door'),
      _SymptomItem('ice',     'symptom_fridge_ice'),
      _SymptomItem('other',   'symptom_other'),
    ],
    'washer': [
      _SymptomItem('no_spin',    'symptom_washer_no_spin'),
      _SymptomItem('water_leak', 'symptom_washer_water_leak'),
      _SymptomItem('noise',      'symptom_washer_noise'),
      _SymptomItem('no_power',   'symptom_washer_no_power'),
      _SymptomItem('other',      'symptom_other'),
    ],
    'tv': [
      _SymptomItem('no_display', 'symptom_tv_no_display'),
      _SymptomItem('no_sound',   'symptom_tv_no_sound'),
      _SymptomItem('no_power',   'symptom_tv_no_power'),
      _SymptomItem('remote',     'symptom_tv_remote'),
      _SymptomItem('other',      'symptom_other'),
    ],
    'water_purifier': [
      _SymptomItem('water_leak', 'symptom_wp_water_leak'),
      _SymptomItem('no_cold',    'symptom_wp_no_cold'),
      _SymptomItem('no_hot',     'symptom_wp_no_hot'),
      _SymptomItem('filter',     'symptom_wp_filter'),
      _SymptomItem('other',      'symptom_other'),
    ],
    'fan': [
      _SymptomItem('no_spin',  'symptom_fan_no_spin'),
      _SymptomItem('noise',    'symptom_fan_noise'),
      _SymptomItem('no_power', 'symptom_fan_no_power'),
      _SymptomItem('other',    'symptom_other'),
    ],
    'rice_cooker': [
      _SymptomItem('no_cook',  'symptom_rc_no_cook'),
      _SymptomItem('no_heat',  'symptom_rc_no_heat'),
      _SymptomItem('no_power', 'symptom_rc_no_power'),
      _SymptomItem('other',    'symptom_other'),
    ],
    'generator': [
      _SymptomItem('no_start',  'symptom_gen_no_start'),
      _SymptomItem('no_power',  'symptom_gen_no_power'),
      _SymptomItem('noise',     'symptom_gen_noise'),
      _SymptomItem('fuel_leak', 'symptom_gen_fuel_leak'),
      _SymptomItem('other',     'symptom_other'),
    ],
    'other': [
      _SymptomItem('broken',   'symptom_other_broken'),
      _SymptomItem('noise',    'symptom_other_noise'),
      _SymptomItem('no_power', 'symptom_other_no_power'),
      _SymptomItem('other',    'symptom_other'),
    ],
  };

  void _selectAppliance(String id) {
    onChanged(state.copyWith(
      selectedApplianceId: id,
      selectedSymptomIds: [],
    ));
  }

  void _toggleSymptom(String id) {
    final list = List<String>.from(state.selectedSymptomIds);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    onChanged(state.copyWith(selectedSymptomIds: list));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final symptoms = _symptomsByAppliance[state.selectedApplianceId] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 가전 종류 선택 타이틀
          Text(
            context.t('appliance_select_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('appliance_select_desc'),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // ── 아이콘 카드 그리드
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: _appliances.map((item) => _ApplianceCard(
              emoji: item.emoji,
              label: context.t(item.labelKey),
              selected: state.selectedApplianceId == item.id,
              onTap: () => _selectAppliance(item.id),
            )).toList(),
          ),

          // ── 증상 선택 (가전 선택 후 애니메이션으로 등장)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: state.selectedApplianceId.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // 선택된 가전 요약 태그
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _appliances
                                      .firstWhere((a) => a.id == state.selectedApplianceId)
                                      .emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.t(_appliances
                                      .firstWhere((a) => a.id == state.selectedApplianceId)
                                      .labelKey),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.t('request_step1_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('request_step1_desc'),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...symptoms.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChoiceChip(
                              label: context.t(e.labelKey),
                              selected: state.selectedSymptomIds.contains(e.id),
                              onTap: () => _toggleSymptom(e.id),
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 데이터 모델
class _ApplianceItem {
  const _ApplianceItem(this.id, this.labelKey, this.emoji);
  final String id;
  final String labelKey;
  final String emoji;
}

class _SymptomItem {
  const _SymptomItem(this.id, this.labelKey);
  final String id;
  final String labelKey;
}

// ── 아이콘 카드 위젯 (가전 종류 선택)
class _ApplianceCard extends StatelessWidget {
  const _ApplianceCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.4),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 증상 선택 칩 (복수 선택)
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
