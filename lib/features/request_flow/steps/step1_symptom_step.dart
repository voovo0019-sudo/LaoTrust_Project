// Step 1: 증상 선택 (70% 동선). 객관식, 중복 선택, 파란 테두리 강조. / Symptom selection.

import 'package:flutter/material.dart';
import '../request_flow_state.dart';

class Step1SymptomStep extends StatelessWidget {
  const Step1SymptomStep({
    super.key,
    required this.state,
    required this.onChanged,
  });
  final RequestFlowState state;
  final ValueChanged<RequestFlowState> onChanged;

  static const List<MapEntry<String, String>> _symptoms = [
    MapEntry('cold_off', '찬바람 안 나옴'),
    MapEntry('noise', '소음'),
    MapEntry('water_leak', '물 새는 소리'),
    MapEntry('not_cool', '시원하지 않음'),
    MapEntry('other', '기타'),
  ];

  void _toggle(String id) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어떤 증상이 있나요?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '해당하는 항목을 모두 선택해 주세요.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ..._symptoms.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceChip(
                  label: e.value,
                  selected: state.selectedSymptomIds.contains(e.key),
                  onTap: () => _toggle(e.key),
                ),
              )),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary.withValues(alpha: 0.12) : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? colorScheme.primary : colorScheme.onSurface,
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
