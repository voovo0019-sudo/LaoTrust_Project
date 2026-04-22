// =============================================================================
// wizard_common.dart
// 공통 헬퍼 함수 및 상수 (모든 Step에서 공유)
// =============================================================================
import 'package:flutter/material.dart';

const Color kWizardRoyalBlue = Color(0xFF1E3A8A);

InputDecoration wizardOutlineFieldDecoration(
  String label, {
  String? hint,
  bool isRequired = false,
  bool hasError = false,
  String? errorText,
}) {
  final displayLabel = isRequired ? '$label *' : label;
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
    labelStyle: isRequired ? const TextStyle(color: Colors.black87) : null,
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
