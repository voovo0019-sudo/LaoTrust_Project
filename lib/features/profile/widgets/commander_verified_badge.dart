// =============================================================================
// v1.3: 사령관 인증(Commander Approved) 메탈릭 골드 인장
// 프로필 사진 우측 하단에 "Verified by Commander" 배지 노출.
// =============================================================================

import 'package:flutter/material.dart';

const Color _metallicGold = Color(0xFFD4AF37);
const Color _metallicGoldDark = Color(0xFFB8962E);

/// 프로필 사진 우하단에 겹쳐 표시할 메탈릭 골드 인장 + "Verified by Commander"
class CommanderVerifiedBadge extends StatelessWidget {
  const CommanderVerifiedBadge({
    super.key,
    this.size = 28,
    this.showLabel = true,
  });

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_metallicGold, _metallicGoldDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _metallicGold.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: size * 0.7),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'Verified by Commander',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 아바타 우하단에 작게 붙일 수 있는 원형 인장만 (라벨 없음)
class CommanderVerifiedBadgeChip extends StatelessWidget {
  const CommanderVerifiedBadgeChip({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_metallicGold, _metallicGoldDark],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _metallicGold.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(Icons.verified, color: Colors.white, size: size * 0.6),
    );
  }
}
