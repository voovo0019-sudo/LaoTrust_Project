// =============================================================================
// wizard_common.dart
// 공통 헬퍼 함수 및 상수 (모든 Step에서 공유)
// =============================================================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/translation_mapper.dart';

const Color kWizardRoyalBlue = Color(0xFF1E3A8A);

InputDecoration wizardOutlineFieldDecoration(
  String label, {
  String? hint,
  bool isRequired = false,
  bool hasError = false,
  String? errorText,
}) {
  final displayLabel = label;
  return InputDecoration(
    labelText: displayLabel,
    hintText: hint,
    errorText: hasError ? errorText : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(
        color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
        width: hasError ? 1.5 : 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(
        color: hasError ? Colors.red.shade400 : kWizardRoyalBlue,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
    ),
    filled: true,
    fillColor: hasError ? Colors.red.shade50 : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: null,
    floatingLabelStyle: TextStyle(
      color: hasError ? Colors.red.shade600 : kWizardRoyalBlue,
    ),
  );
}

Widget wizardOutlineToggleTile({
  required String label,
  required bool selected,
  required VoidCallback onTap,
  IconData? icon,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? kWizardRoyalBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? kWizardRoyalBlue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: selected ? kWizardRoyalBlue : Colors.grey, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? kWizardRoyalBlue : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 글로벌 수준 시간 드럼 피커 (알바 + 9개 카테고리 공통 사용)
/// 반환값: "HH:mm" 문자열, 취소 시 null
Future<String?> showTimePickerDrum(
  BuildContext context, {
  String initialTime = '09:00',
}) async {
  final lang = Localizations.localeOf(context).languageCode;
  String t(String key) =>
      kStaticUiTripleByMessageKey[key]?[lang] ??
      kStaticUiTripleByMessageKey[key]?['en'] ??
      key;

  final parts = initialTime.split(':');
  int selectedHour = int.tryParse(parts[0]) ?? 9;
  int selectedMinute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

  // 무한 루프 트릭: 9999개 아이템, 중간(4999)에서 시작
  const int loopCount = 9999;
  const int loopMid = 4999;
  final hourController = FixedExtentScrollController(
    initialItem: loopMid + selectedHour,
  );
  final minuteController = FixedExtentScrollController(
    initialItem: loopMid + selectedMinute,
  );

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF1E3A8A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.schedule, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t('time_picker_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        t('time_picker_hour'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kWizardRoyalBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Center(
                      child: Text(
                        t('time_picker_minute'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kWizardRoyalBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 76,
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: kWizardRoyalBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kWizardRoyalBlue.withValues(alpha: 0.45),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kWizardRoyalBlue.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: hourController,
                              itemExtent: 48,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (i) {
                                selectedHour = i % 24;
                                setState(() {});
                              },
                              children: List.generate(loopCount, (i) {
                                final val = i % 24;
                                final isSelected = val == selectedHour;
                                return Center(
                                  child: Text(
                                    val.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: isSelected ? 30 : 24,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? kWizardRoyalBlue
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: minuteController,
                              itemExtent: 48,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (i) {
                                selectedMinute = i % 60;
                                setState(() {});
                              },
                              children: List.generate(loopCount, (i) {
                                final val = i % 60;
                                final isSelected = val == selectedMinute;
                                return Center(
                                  child: Text(
                                    val.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: isSelected ? 30 : 24,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? kWizardRoyalBlue
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWizardRoyalBlue,
                        side: const BorderSide(color: kWizardRoyalBlue, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        t('time_picker_cancel'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF1E3A8A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: kWizardRoyalBlue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final h = selectedHour.toString().padLeft(2, '0');
                          final m = selectedMinute.toString().padLeft(2, '0');
                          Navigator.of(ctx).pop('$h:$m');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              t('time_picker_confirm'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      );
    },
  );

  hourController.dispose();
  minuteController.dispose();
  return result;
}
