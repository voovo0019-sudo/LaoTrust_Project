// =============================================================================
// MyRequestsScreen - 나의 신청현황 (독립 화면)
// 글로벌 표준 구조: profile_screen.dart에서 분리
// =============================================================================
import 'dart:async' show TimeoutException;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  static const String routePath = '/my_requests';

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _future;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _future = _loadMyRequests();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadMyRequests() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return const [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('requests')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 10));
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return docs;
    } on TimeoutException catch (_) {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _future = _loadMyRequests();
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isRetrying = false);
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(context.l10n('profile_menu_my_requests')),
        actions: [
          IconButton(
            icon: _isRetrying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _retry,
          ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n('profile_my_requests_load_failed'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n('retry')),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n('profile_my_requests_empty')),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n('retry')),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final category = (data['category'] ?? '').toString();
              final status = (data['status'] ??
                  context.l10n('status')).toString();
              final location = (data['locationText'] ??
                  data['location'] ?? '-').toString();
              final createdAt = _formatDate(data['createdAt']);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                      Icons.assignment_turned_in_outlined),
                  title: Text(category.isEmpty
                      ? context.l10n('request_complete_title')
                      : category),
                  subtitle: Text('$location\n$createdAt'),
                  trailing: Text(
                    status,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
