import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/tab_provider.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';
import '../../data/firestore_schema.dart';

const Color _kRoyalBlue = Color(0xFF1E3A8A);
const double _kRadius = 28.0;

/// 9개 서비스 카테고리 ID. universal_wizard_config.dart의 카테고리 ID와 일치시킬 것.
const List<String> kExpertCategoryIds = [
  'expert_cleaning',
  'expert_moving',
  'expert_repair',
  'expert_interior',
  'expert_business',
  'expert_beauty',
  'expert_tutoring',
  'expert_events',
  'expert_vehicle',
];

class ExpertRegistrationScreen extends ConsumerStatefulWidget {
  const ExpertRegistrationScreen({super.key});

  @override
  ConsumerState<ExpertRegistrationScreen> createState() =>
      _ExpertRegistrationScreenState();
}

class _ExpertRegistrationScreenState
    extends ConsumerState<ExpertRegistrationScreen> {
  final Set<String> _selected = <String>{};
  bool _loading = true;
  bool _saving = false;

  String _langCode(BuildContext context) {
    final raw = Localizations.localeOf(context).languageCode.toLowerCase();
    if (raw.startsWith('ko')) return 'ko';
    if (raw.startsWith('lo')) return 'lo';
    return 'en';
  }

  String _t(BuildContext context, String key) {
    final lang = _langCode(context);
    return kStaticUiTripleByMessageKey[key]?[lang] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// 구버전 카테고리 ID → 신버전 자동 변환 테이블
  static const Map<String, String> _kLegacyIdMap = {
    'cleaning': 'expert_cleaning',
    'moving': 'expert_moving',
    'appliance_repair': 'expert_repair',
    'interior': 'expert_interior',
    'tutoring': 'expert_tutoring',
    'beauty': 'expert_beauty',
    'business': 'expert_business',
    'translation': '', // 위저드에 없음 → 제거
    'pet_care': '', // 위저드에 없음 → 제거
  };

  /// 기존 전문가 등록 정보 로드 + 구버전 ID 자동 마이그레이션
  Future<void> _loadExisting() async {
    try {
      if (!isFirebaseEnabled) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final uid = auth.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final doc = await firestore
          .collection(kColUsers)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final data = doc.data();
      if (data != null && data['categories'] is List) {
        final raw = List<String>.from(data['categories']);

        // 구버전 ID 마이그레이션
        final migrated = <String>{};
        bool needsSave = false;
        for (final id in raw) {
          if (kExpertCategoryIds.contains(id)) {
            // 이미 신버전 ID
            migrated.add(id);
          } else if (_kLegacyIdMap.containsKey(id)) {
            final newId = _kLegacyIdMap[id]!;
            if (newId.isNotEmpty) {
              migrated.add(newId);
            }
            // newId가 비어있으면 제거 (translation, pet_care)
            needsSave = true;
          }
          // 알 수 없는 ID는 무시
        }

        _selected.addAll(migrated);

        // 마이그레이션이 필요했다면 Firestore 자동 업데이트
        if (needsSave && uid.isNotEmpty) {
          await firestore
              .collection(kColUsers)
              .doc(uid)
              .set({
                'categories': migrated.toList(),
                UserFields.updatedAt: FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(const Duration(seconds: 5));
        }
      }
    } catch (_) {
      // 로드/마이그레이션 실패해도 빈 상태로 진행 (오프라인 대응)
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 전문가 등록 저장. user_type=expert, categories 배열 저장.
  /// merge:true 사용 → 기존 general 기능 필드를 절대 덮어쓰지 않음.
  Future<void> _save() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, 'expert_reg_select_required'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (!isFirebaseEnabled) {
        throw Exception('firebase disabled');
      }
      final uid = auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('no uid');
      }
      await firestore
          .collection(kColUsers)
          .doc(uid)
          .set({
            UserFields.userType: kUserTypeExpert,
            'categories': _selected.toList(),
            UserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          title: Text(_t(ctx, 'expert_reg_done_title')),
          content: Text(_t(ctx, 'expert_reg_done_desc')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  ref.read(currentTabProvider.notifier).goHome();
                  context.go('/main');
                }
              },
              child: Text(_t(ctx, 'confirm')),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, 'expert_reg_save_failed'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _t(context, 'expert_reg_title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        _t(context, 'expert_reg_header'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t(context, 'expert_reg_sub'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...kExpertCategoryIds.map((id) {
                        final selected = _selected.contains(id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(_kRadius),
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(id);
                                } else {
                                  _selected.add(id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _kRoyalBlue.withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(_kRadius),
                                border: Border.all(
                                  color: selected
                                      ? _kRoyalBlue
                                      : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: selected
                                        ? _kRoyalBlue
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _t(context,
                                          'cat_${id.replaceAll('expert_', '')}'),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selected
                                            ? _kRoyalBlue
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRoyalBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_kRadius),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _t(context, 'expert_reg_save_btn'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
