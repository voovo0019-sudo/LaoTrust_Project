// =============================================================================
// 홈 화면 UI 전용. 데이터는 FirebaseService를 통해서만 조회.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lao_trust/services/firebase_service.dart';

/// 홈 화면: 전문가 서비스 그리드 + 급구 알바 리스트. UI만 담당.
class HomeScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LAO TRUST 🛡️',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "전문가 서비스",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ),
              _buildExpertSection(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                child: Text(
                  "급구 알바",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ),
              _buildQuickJobSection(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpertSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getExpertServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final services = snapshot.data ?? [];
        if (services.isEmpty) {
          return const Center(child: Text("등록된 서비스가 없습니다."));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            final colorValue = int.tryParse(s['color']?.toString() ?? '0xFF9E9E9E') ?? 0xFF9E9E9E;
            final color = Color(colorValue);
            return InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_getIconData(s['icon'] ?? ''), color: color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['name'] ?? '이름없음',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickJobSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getQuickJobs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return const Center(child: Text("현재 등록된 정보가 없습니다."));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final j = jobs[index];
            final tagColorValue =
                int.tryParse(j['tagColor']?.toString() ?? '0xFF9E9E9E') ?? 0xFF9E9E9E;
            final tagColor = Color(tagColorValue);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  j['title'] ?? '제목없음',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    j['loc'] ?? '위치 정보 없음',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    j['tag'] ?? '알바',
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'security':
        return Icons.security;
      case 'home_repair_service':
        return Icons.home_repair_service;
      case 'build':
        return Icons.build;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'face':
        return Icons.face;
      case 'menu_book':
        return Icons.menu_book;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.help_outline;
    }
  }
}
