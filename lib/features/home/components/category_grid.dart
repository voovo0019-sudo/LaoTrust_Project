import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';

/// 9대 전문가 서비스 카테고리 그리드 (원스크린 압축 버전).
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.onCategorySelected,
  });

  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      // 9대 카테고리 (3x3 그리드). 라벨은 i18n 키로 표시.
      {'key': 'expert_cleaning', 'icon': Icons.cleaning_services, 'color': Colors.cyan},
      {'key': 'expert_security', 'icon': Icons.shield, 'color': const Color(0xFF1E3A8A)},
      {'key': 'expert_repair', 'icon': Icons.build, 'color': Colors.orange},
      {'key': 'expert_delivery', 'icon': Icons.delivery_dining, 'color': Colors.green},
      {'key': 'expert_beauty', 'icon': Icons.face, 'color': Colors.pinkAccent},
      {'key': 'expert_tutoring', 'icon': Icons.menu_book, 'color': Colors.purple},
      {'key': 'expert_photo', 'icon': Icons.camera_alt, 'color': Colors.amber},
      {'key': 'expert_event', 'icon': Icons.celebration, 'color': Colors.indigo},
      {'key': 'expert_garden', 'icon': Icons.park_outlined, 'color': Colors.teal},
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // 상하·좌우 여백을 초밀도로 조정 (mainAxisSpacing ≤ 2, crossAxisSpacing ≤ 4)
        mainAxisSpacing: 2,
        crossAxisSpacing: 4,
        // 카테고리 셀의 물리적 세로 높이를 직접 고정
        mainAxisExtent: 88.0,
        childAspectRatio: 0.9,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        final Color color = s['color'] as Color;
        final String labelKey = s['key'] as String;

        return InkWell(
          onTap: () => onCategorySelected(labelKey),
          borderRadius: BorderRadius.circular(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  s['icon'] as IconData,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(height: 0),
              Text(
                context.l10n(labelKey),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Sans',
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

