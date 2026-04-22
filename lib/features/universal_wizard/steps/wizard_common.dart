// =============================================================================
// wizard_common.dart
// 공통 헬퍼 함수 및 상수 (모든 Step에서 공유)
// =============================================================================
import 'package:flutter/material.dart';

const Color kWizardRoyalBlue = Color(0xFF1E3A8A);

InputDecoration wizardOutlineFieldDecoration(
  String label, {
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: kWizardRoyalBlue, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
