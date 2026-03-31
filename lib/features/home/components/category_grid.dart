import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';

/// v5.0 — 9대 전문가 서비스 카테고리 그리드 (3×3).
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.onCategorySelected,
  });

  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'key': 'expert_cleaning', 'icon': Icons.cleaning_services, 'color': Colors.cyan},
      {'key': 'expert_moving', 'icon': Icons.local_shipping, 'color': Colors.green},
      {'key': 'expert_repair', 'icon': Icons.build, 'color': Colors.orange},
      {'key': 'expert_interior', 'icon': Icons.home_work_outlined, 'color': const Color(0xFF7C3AED)},
      {'key': 'expert_business', 'icon': Icons.translate, 'color': const Color(0xFF1E3A8A)},
      {'key': 'expert_beauty', 'icon': Icons.spa_outlined, 'color': Colors.pinkAccent},
      {'key': 'expert_tutoring', 'icon': Icons.menu_book, 'color': Colors.purple},
      {'key': 'expert_events', 'icon': Icons.celebration, 'color': Colors.indigo},
      {'key': 'expert_vehicle', 'icon': Icons.directions_car_filled_outlined, 'color': Colors.teal},
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 4,
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
