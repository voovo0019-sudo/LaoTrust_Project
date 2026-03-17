// =============================================================================
// v1.3: 디지털 파트너 ID 카드 — 전문가별 고유 시리얼 번호가 담긴 명품 카드 UI
// =============================================================================

import 'package:flutter/material.dart';

const Color _royalNavy = Color(0xFF1E293B);
const Color _metallicGold = Color(0xFFD4AF37);

class DigitalPartnerIdCard extends StatelessWidget {
  const DigitalPartnerIdCard({
    super.key,
    required this.serialId,
    this.displayName,
    this.photoUrl,
    this.categoryLabel,
  });

  final String serialId;
  final String? displayName;
  final String? photoUrl;
  final String? categoryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _royalNavy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _royalNavy.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _metallicGold.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _metallicGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(photoUrl!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.person, color: _metallicGold, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? 'LaoTrust Partner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (categoryLabel != null && categoryLabel!.isNotEmpty)
                      Text(
                        categoryLabel!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: _metallicGold.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'PARTNER ID',
            style: TextStyle(
              color: _metallicGold.withValues(alpha: 0.9),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            serialId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.verified, size: 14, color: _metallicGold),
              const SizedBox(width: 4),
              Text(
                'Verified by Commander',
                style: TextStyle(
                  color: _metallicGold.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
