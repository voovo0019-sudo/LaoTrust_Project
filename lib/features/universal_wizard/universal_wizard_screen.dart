// =============================================================================
// v5.1: 유니버설 4단계 위저드 — Storage URL 저장 · D2 설계도 반영
// Firestore: artifacts/{projectId}/public/data/requests
// =============================================================================

import 'dart:async' show TimeoutException, unawaited;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_localizations.dart';
import '../../core/expert_request_photo_upload.dart';
import '../../core/firebase_service.dart';
import '../../core/location_service.dart';
import '../../core/offline_first_sync.dart';
import '../../core/search_trigger_bus.dart';
import '../../core/translation_mapper.dart';
import 'universal_wizard_config.dart';
import 'universal_wizard_state.dart';
import 'widgets/settlement_guide_widget.dart';
import '../../services/auth_service.dart';

class UniversalWizardScreen extends StatefulWidget {
  const UniversalWizardScreen({
    super.key,
    required this.categoryKey,
    this.initialSubTypeId,
    this.initialSubTypeLabel,
  });

  static const String routeName = '/universal-wizard';
  final String categoryKey;
  final String? initialSubTypeId;
  final String? initialSubTypeLabel;

  @override
  State<UniversalWizardScreen> createState() => _UniversalWizardScreenState();
}

const Color _kRoyalBlue = Color(0xFF1E3A8A);

class _UniversalWizardScreenState extends State<UniversalWizardScreen> {
  static const int totalSteps = 4;
  late PageController _pageController;
  late UniversalWizardState _state;
  UniversalWizardConfig? _config;
  int _currentStep = 0;
  bool _isSubmitting = false;

  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _pickedImages = <XFile>[];

  final Set<String> _step2Selections = <String>{};
  bool _step2OtherSelected = false;
  final TextEditingController _step2OtherController = TextEditingController();
  final TextEditingController _step1OtherServiceController = TextEditingController();

  final TextEditingController _weightKgController = TextEditingController();
  final TextEditingController _movingRoomCountController = TextEditingController();
  String _movingVehicleType = '';

  final TextEditingController _cleaningAreaController = TextEditingController();
  String _cleaningScale = '';
  final TextEditingController _cleaningTargetController = TextEditingController();
  final TextEditingController _cleaningIndustryController = TextEditingController();
  final TextEditingController _cleaningBeddingCountController = TextEditingController();

  final Set<String> _tutoringLevels = <String>{};
  final TextEditingController _tutorGoalController = TextEditingController();

  final TextEditingController _eventPeopleController = TextEditingController();

  final Set<String> _interiorParts = <String>{};
  final TextEditingController _interiorBudgetController = TextEditingController();

  final Set<String> _businessLangs = <String>{};
  final TextEditingController _documentTypeController = TextEditingController();

  final Set<String> _vehicleSymptoms = <String>{};
  final TextEditingController _vehicleBrandController = TextEditingController();

  final TextEditingController _beautyPeopleController = TextEditingController();

  final TextEditingController _d3LandmarkController = TextEditingController();
  final TextEditingController _d3MovingFromController = TextEditingController();
  final TextEditingController _d3MovingToController = TextEditingController();
  final TextEditingController _d3MemoController = TextEditingController();

  String _repairBrand = '';
  final TextEditingController _repairSymptomMemoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _config = kUniversalWizardConfigs[widget.categoryKey];
    _state = UniversalWizardState(
      categoryKey: widget.categoryKey,
      step1SubTypeId: widget.initialSubTypeId ?? '',
      step1SubTypeLabel: widget.initialSubTypeLabel ?? '',
    );
    if (widget.initialSubTypeId != null && widget.initialSubTypeId!.isNotEmpty) {
      _currentStep = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(1);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _step2OtherController.dispose();
    _step1OtherServiceController.dispose();
    _weightKgController.dispose();
    _movingRoomCountController.dispose();
    _cleaningAreaController.dispose();
    _cleaningTargetController.dispose();
    _cleaningIndustryController.dispose();
    _cleaningBeddingCountController.dispose();
    _tutorGoalController.dispose();
    _eventPeopleController.dispose();
    _interiorBudgetController.dispose();
    _documentTypeController.dispose();
    _vehicleBrandController.dispose();
    _beautyPeopleController.dispose();
    _d3LandmarkController.dispose();
    _d3MovingFromController.dispose();
    _d3MovingToController.dispose();
    _d3MemoController.dispose();
    _repairSymptomMemoController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _checkAuthAndRedirect() {
    if (!mounted) return;
    // 전화번호 로그인만 통과 (익명 로그인은 통과 불가)
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) return;
    // 화이트리스트 로그인 확인 (whitelistDisplayPhoneNotifier에 값이 있으면 통과)
    final whitePhone = whitelistDisplayPhoneNotifier.value?.trim() ?? '';
    if (whitePhone.isNotEmpty) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('로그인이 필요합니다'),
        content: const Text('서비스를 이용하려면 전화번호로 로그인해 주세요.'),
        actions: [
          OutlinedButton(
            onPressed: () {
              final catKey = widget.categoryKey;
              final subId = widget.initialSubTypeId;
              final subLabel = widget.initialSubTypeLabel;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              setPostLoginRedirect(
                UniversalWizardScreen.routeName,
                <String, dynamic>{
                  'categoryKey': catKey,
                  'initialSubTypeId': subId,
                  'initialSubTypeLabel': subLabel,
                },
              );
              Navigator.of(context).pushNamed('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  bool _canProceedStep1() => _state.step1SubTypeId.isNotEmpty;

  bool _canProceedStep2() {
    if (_state.step1SubTypeId == 'other') {
      return _step1OtherServiceController.text.trim().isNotEmpty;
    }
    switch (_state.categoryKey) {
      case 'expert_moving':
        final sub = _state.step1SubTypeId;
        if (sub == 'small') return _movingVehicleType.isNotEmpty;
        if (sub == 'home') return _movingRoomCountController.text.trim().isNotEmpty;
        if (sub == 'cargo') return _weightKgController.text.trim().isNotEmpty;
        return false;
      case 'expert_cleaning':
        final hasBase =
            _cleaningAreaController.text.trim().isNotEmpty || _cleaningScale.isNotEmpty;
        if (!hasBase) return false;
        final sub = _state.step1SubTypeId;
        if (sub == 'commercial') return _cleaningIndustryController.text.trim().isNotEmpty;
        if (sub == 'regular_visit') return _cleaningTargetController.text.trim().isNotEmpty;
        if (sub == 'bedding') return _cleaningBeddingCountController.text.trim().isNotEmpty;
        return true;
      case 'expert_repair':
        return _repairBrand.isNotEmpty && _repairSymptomMemoController.text.trim().isNotEmpty;
      case 'expert_interior':
        if (_interiorParts.isEmpty) return false;
        if (_state.step1SubTypeId == 'remodel') {
          return _interiorBudgetController.text.trim().isNotEmpty;
        }
        return true;
      case 'expert_business':
        return _businessLangs.isNotEmpty && _documentTypeController.text.trim().isNotEmpty;
      case 'expert_beauty':
        final kindOk = _step2Selections.isNotEmpty || _step2OtherSelected;
        if (!kindOk) return false;
        if (_step2OtherSelected && _step2OtherController.text.trim().isEmpty) return false;
        return _beautyPeopleController.text.trim().isNotEmpty;
      case 'expert_tutoring':
        return _tutoringLevels.isNotEmpty;
      case 'expert_events':
        return _eventPeopleController.text.trim().isNotEmpty;
      case 'expert_vehicle':
        return _vehicleBrandController.text.trim().isNotEmpty &&
            (_vehicleSymptoms.isNotEmpty || _step2OtherSelected);
      default:
        return _step2Selections.isNotEmpty || _step2OtherSelected;
    }
  }

  bool _canProceedStep3() {
    final dateOk = _state.preferredDateStr.isNotEmpty;
    final timeOk = _state.preferredTimeStr.isNotEmpty;
    if (!dateOk || !timeOk) return false;
    final hasPin = _state.step3Lat != null && _state.step3Lng != null;
    final hasLandmark = _d3LandmarkController.text.trim().isNotEmpty;
    if (!hasPin && !hasLandmark) return false;
    if (_state.categoryKey == 'expert_moving') {
      return _d3MovingFromController.text.trim().isNotEmpty &&
          _d3MovingToController.text.trim().isNotEmpty;
    }
    return true;
  }

  bool _canProceedStep4() => true;

  String _categoryEnglish(String key) {
    return switch (key) {
      'expert_cleaning' => 'Cleaning',
      'expert_moving' => 'Moving',
      'expert_repair' => 'Repair',
      'expert_interior' => 'Interior',
      'expert_business' => 'Business',
      'expert_beauty' => 'Beauty',
      'expert_tutoring' => 'Lessons',
      'expert_events' => 'Events',
      'expert_vehicle' => 'Vehicle',
      _ => 'Other',
    };
  }

  String _subTypePascal(String id) {
    if (id.isEmpty) return 'Other';
    final parts = id.split('_');
    return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }

  /// 급구 [TranslationMapper]와 동일한 4슬롯(title/location/salary/detail)으로 요약 문자열을 묶는다.
  /// Step 4에는 호출하지 않고, [ _submit ]에서만 번역에 사용한다.
  Map<String, String> _wizardTranslationInput(UniversalWizardConfig config) {
    final buf = StringBuffer();
    final d2 = _buildDepth2Map();
    d2.forEach((k, v) => buf.writeln('$k: $v'));
    final depth2Str = buf.toString().trim();

    final locStr = _state.categoryKey == 'expert_moving'
        ? '${context.l10n('wizard_depth3_from_label')}: ${_d3MovingFromController.text}\n'
            '${context.l10n('wizard_depth3_to_label')}: ${_d3MovingToController.text}\n'
            '${context.l10n('wizard_depth3_landmark_label')}: ${_d3LandmarkController.text}'
        : _d3LandmarkController.text;

    final titleStr = [
      context.l10n(config.categoryKey),
      if (_state.step1SubTypeLabel.isNotEmpty) context.l10n(_state.step1SubTypeLabel),
    ].join(' · ');

    final scheduleStr =
        '${_state.preferredDateStr} ${_state.preferredTimeStr} (${_state.scheduleIsUrgent ? context.l10n('wizard_schedule_urgent') : context.l10n('wizard_schedule_normal')})';

    final detailParts = <String>[
      if (depth2Str.isNotEmpty) depth2Str,
      if (_d3MemoController.text.trim().isNotEmpty) _d3MemoController.text.trim(),
    ];
    final detailStr = detailParts.join('\n');

    return {
      'title': titleStr.trim(),
      'location': locStr.trim(),
      'salary': scheduleStr.trim(),
      'detail': detailStr.trim(),
    };
  }

  Map<String, dynamic> _buildDepth2Map() {
    if (_state.step1SubTypeId == 'other') {
      return {'customService': _step1OtherServiceController.text.trim()};
    }
    switch (_state.categoryKey) {
      case 'expert_cleaning':
        return {
          'areaOrSize': _cleaningAreaController.text.trim(),
          'scale': _cleaningScale,
          if (_state.step1SubTypeId == 'commercial')
            'industry': _cleaningIndustryController.text.trim(),
          if (_state.step1SubTypeId == 'regular_visit')
            'target': _cleaningTargetController.text.trim(),
          if (_state.step1SubTypeId == 'bedding')
            'beddingCount': _cleaningBeddingCountController.text.trim(),
          if (_step2OtherSelected) 'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_moving':
        return {
          if (_state.step1SubTypeId == 'small') 'vehicleType': _movingVehicleType,
          if (_state.step1SubTypeId == 'home') 'roomCount': _movingRoomCountController.text.trim(),
          if (_state.step1SubTypeId == 'cargo') 'cargoWeightKg': _weightKgController.text.trim(),
        };
      case 'expert_repair':
        return {
          'brand': _repairBrand,
          'symptomDetail': _repairSymptomMemoController.text.trim(),
        };
      case 'expert_interior':
        return {
          'parts': _interiorParts.toList(),
          if (_state.step1SubTypeId == 'remodel')
            'budgetRange': _interiorBudgetController.text.trim(),
        };
      case 'expert_business':
        return {
          'languages': _businessLangs.toList(),
          'documentKind': _documentTypeController.text.trim(),
          if (_step2OtherSelected) 'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_beauty':
        return {
          'kinds': _step2Selections.toList(),
          'people': _beautyPeopleController.text.trim(),
          if (_step2OtherSelected) 'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_tutoring':
        return {
          'subject': _state.step1SubTypeId,
          'levels': _tutoringLevels.toList(),
          'goal': _tutorGoalController.text.trim(),
          if (_step2OtherSelected) 'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_events':
        return {
          'eventKind': _state.step1SubTypeId,
          'expectedPeople': _eventPeopleController.text.trim(),
        };
      case 'expert_vehicle':
        return {
          'brandOrModel': _vehicleBrandController.text.trim(),
          'symptoms': _vehicleSymptoms.toList(),
          if (_step2OtherSelected) 'otherNote': _step2OtherController.text.trim(),
        };
      default:
        return {
          'selections': _step2Selections.toList(),
          if (_step2OtherSelected) 'otherNote': _step2OtherController.text.trim(),
        };
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    // ignore: avoid_print
    print('[SUBMIT] 시작');

    final cfg = _config ?? kUniversalWizardConfigs['expert_repair']!;
    final txInput = _wizardTranslationInput(cfg);
    final localeCode = Localizations.localeOf(context).languageCode;

    final uid = auth.currentUser?.uid ?? employerIdForCurrentSession() ?? '';
    List<String> photoUrls = <String>[];
    List<String>? photoLocalPaths;

    try {
      if (_pickedImages.isNotEmpty) {
        if (!isFirebaseEnabled) {
          // ignore: avoid_print
          print('[SUBMIT] Firebase 비활성 — 사진 없이 신청 계속');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n('wizard_need_firebase_for_photos'))),
            );
          }
          photoUrls = <String>[];
        } else {
          // ignore: avoid_print
          print('[SUBMIT] 연결 확인 시작');
          List<ConnectivityResult> conn = <ConnectivityResult>[];
          try {
            conn = await Connectivity()
                .checkConnectivity()
                .timeout(const Duration(seconds: 30));
          } on TimeoutException catch (e) {
            if (kDebugMode) debugPrint('UniversalWizard: 연결 확인 타임아웃: $e');
            conn = <ConnectivityResult>[];
          } on Object catch (e, st) {
            if (kDebugMode) {
              debugPrint('UniversalWizard: 연결 확인 실패: $e');
              debugPrint('$st');
            }
            conn = <ConnectivityResult>[];
          }
          final online = conn.any((e) =>
              e == ConnectivityResult.mobile ||
              e == ConnectivityResult.wifi ||
              e == ConnectivityResult.ethernet);
          // ignore: avoid_print
          print('[SUBMIT] 연결 확인 완료 (online=$online)');
          if (online) {
            if (!mounted) return;
            final lang = Localizations.localeOf(context).languageCode;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        kStaticUiTripleByMessageKey['uploading_photos']?[lang] ??
                            '사진 업로드 중...',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
            try {
              // ignore: avoid_print
              print('[SUBMIT] 사진업로드 시작');
              photoUrls = await uploadExpertRequestImagesFromXFiles(
                files: _pickedImages,
                userId: uid,
              ).timeout(const Duration(seconds: 30));
              // ignore: avoid_print
              print('[SUBMIT] 사진업로드 결과: ${photoUrls.length}개 URL');
            } on TimeoutException catch (e) {
              if (kDebugMode) debugPrint('UniversalWizard: 사진 업로드 타임아웃: $e');
              // ignore: avoid_print
              print('[SUBMIT] 사진업로드 타임아웃 — photoUrls=[] 로 번역·저장 계속');
              photoUrls = <String>[];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n('wizard_upload_failed'))),
                );
              }
            } on Object catch (e, st) {
              if (kDebugMode) {
                debugPrint('UniversalWizard: 사진 업로드 실패: $e');
                debugPrint('$st');
              }
              // ignore: avoid_print
              print('[SUBMIT] 사진업로드 실패 — photoUrls=[] 로 번역·저장 계속: $e');
              photoUrls = <String>[];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n('wizard_upload_failed'))),
                );
              }
            } finally {
              // ignore: avoid_print
              print('[SUBMIT] 사진업로드 블록 finally (다이얼로그 닫기)');
              if (mounted) Navigator.of(context).pop();
            }
          } else {
            photoLocalPaths =
                _pickedImages.map((e) => e.path).where((s) => s.isNotEmpty).toList();
            // ignore: avoid_print
            print('[SUBMIT] 오프라인 — 로컬 경로 ${_pickedImages.length}건, 업로드 생략');
          }
        }
      } else {
        // ignore: avoid_print
        print('[SUBMIT] 선택된 사진 없음 — 바로 번역 단계');
      }

      final location = <String, dynamic>{
        'lat': _state.step3Lat ?? 0.0,
        'lng': _state.step3Lng ?? 0.0,
        'landmark': _d3LandmarkController.text.trim(),
        if (_state.categoryKey == 'expert_moving') ...{
          'fromLandmark': _d3MovingFromController.text.trim(),
          'toLandmark': _d3MovingToController.text.trim(),
        },
      };

      Map<String, Map<String, String>> wizardI18n =
          TranslationMapper.rawTripleBundleForFields(txInput);
      var translateProgressShown = false;
      if (mounted) {
        translateProgressShown = true;
        final lang = Localizations.localeOf(context).languageCode;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    kStaticUiTripleByMessageKey['translating_request']?[lang] ??
                        '번역 중...',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // ignore: avoid_print
      print('[SUBMIT] 번역 시작');
      try {
        final tResult = await TranslationMapper.translateAllFieldsStrict(
          txInput,
          sourceLanguageCode: localeCode,
        ).timeout(const Duration(seconds: 30));
        wizardI18n = tResult.bundle ?? TranslationMapper.rawTripleBundleForFields(txInput);
      } on TimeoutException catch (e) {
        if (kDebugMode) debugPrint('UniversalWizard: 번역 타임아웃 — 원문 트리플 저장: $e');
      } on Object catch (e, st) {
        if (kDebugMode) {
          debugPrint('UniversalWizard: 번역 실패 — 원문 트리플 저장: $e');
          debugPrint('$st');
        }
      } finally {
        if (kDebugMode) debugPrint('UniversalWizard: 번역 단계 종료(상한 30초)');
      }
      if (translateProgressShown && mounted) {
        Navigator.of(context).pop();
      }
      // ignore: avoid_print
      print('[SUBMIT] 번역 완료');

      final body = <String, dynamic>{
        'category': _categoryEnglish(_state.categoryKey),
        'subType': _subTypePascal(_state.step1SubTypeId),
        'depth2Data': _buildDepth2Map(),
        'location': location,
        'schedule': {
          'date': _state.preferredDateStr,
          'time': _state.preferredTimeStr,
          'isUrgent': _state.scheduleIsUrgent,
        },
        'photos': photoUrls,
        'memo': _d3MemoController.text.trim(),
        'status': 'pending',
        'wizardI18n': wizardI18n,
      };
      if (photoLocalPaths != null && photoLocalPaths.isNotEmpty) {
        body['_photoLocalPaths'] = photoLocalPaths;
      }

      var submitProgressShown = false;
      if (mounted) {
        submitProgressShown = true;
        final lang = Localizations.localeOf(context).languageCode;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    kStaticUiTripleByMessageKey['submitting_request']?[lang] ??
                        '전문가에게 전달 중...',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // ignore: avoid_print
      print('[SUBMIT] Firestore 저장 시작 (photos=${photoUrls.length}개)');
      unawaited(
        saveExpertRequestV5OfflineFirst(body).then((_) {
          debugPrint('[SUBMIT] Firestore 저장 성공 (Background)');
        }).catchError((e) {
          debugPrint('[SUBMIT ERROR] 백그라운드 저장 중 범인 발생: $e');
        }),
      );
      if (submitProgressShown && mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      // ignore: avoid_print
      print('[SUBMIT] 에러: $e');
      rethrow;
    } finally {
      // ignore: avoid_print
      print('[SUBMIT] finally 실행');
      if (mounted) setState(() => _isSubmitting = false);
    }

    // finally 완전히 끝난 후
    debugPrint('[SUBMIT] 유저 응답성 확보를 위해 즉시 팝업 호출');
    if (!mounted) return;
    _showSuccessDialog();
  }

  /// 전문가 신청 완료 팝업 (즉시 호출용)
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('신청 완료', textAlign: TextAlign.center),
          content: const Text(
            '전문가에게 요청이 성공적으로 전달되었습니다.\n잠시만 기다려주시면 전문가가 연락을 드립니다.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  SearchTriggerBus.trigger();
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRoyalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _outlineFieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: _kRoyalBlue, width: 1.2),
      ),
    );
  }

  Widget _outlineToggleTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? _kRoyalBlue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? _kRoyalBlue : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: _kRoyalBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _photoPromptForCategory() {
    return switch (_state.categoryKey) {
      'expert_repair' => context.l10n('wizard_photo_prompt_repair'),
      'expert_moving' => context.l10n('wizard_photo_prompt_moving'),
      'expert_beauty' => context.l10n('wizard_photo_prompt_style_concept'),
      'expert_events' => context.l10n('wizard_photo_prompt_event'),
      'expert_cleaning' => context.l10n('wizard_photo_prompt_cleaning'),
      'expert_tutoring' => context.l10n('wizard_photo_prompt_tutoring'),
      'expert_business' => context.l10n('wizard_photo_prompt_business'),
      'expert_interior' => context.l10n('wizard_photo_prompt_interior'),
      'expert_vehicle' => context.l10n('wizard_photo_prompt_vehicle'),
      _ => context.l10n('wizard_photo_prompt_generic'),
    };
  }

  Future<void> _pickImagesFromGallery({required int maxCount}) async {
    final remaining = (maxCount - _pickedImages.length).clamp(0, maxCount);
    if (remaining <= 0) return;
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    if (images.isEmpty) return;
    setState(() {
      _pickedImages.addAll(images.take(remaining));
      _state = _state.copyWith(step3PhotoPaths: _pickedImages.map((e) => e.path).toList());
    });
  }

  Future<void> _pickImageFromCamera({required int maxCount}) async {
    if (_pickedImages.length >= maxCount) return;
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    if (image == null) return;
    setState(() {
      _pickedImages.add(image);
      _state = _state.copyWith(step3PhotoPaths: _pickedImages.map((e) => e.path).toList());
    });
  }

  void _removePickedImageAt(int index) {
    if (index < 0 || index >= _pickedImages.length) return;
    setState(() {
      _pickedImages.removeAt(index);
      _state = _state.copyWith(step3PhotoPaths: _pickedImages.map((e) => e.path).toList());
    });
  }

  Future<void> _useCurrentGps() async {
    final (loc, _) = await getUserLocationOrDefault();
    if (!mounted) return;
    setState(() {
      _state = _state.copyWith(step3Lat: loc.latitude, step3Lng: loc.longitude);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n('wizard_depth3_gps_saved'))),
    );
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    setState(() => _state = _state.copyWith(preferredDateStr: '$y-$m-$day'));
  }

  Future<void> _pickPreferredTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null || !mounted) return;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    setState(() => _state = _state.copyWith(preferredTimeStr: '$h:$m'));
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            context
                .l10n('wizard_step_progress')
                .replaceAll('{current}', '${_currentStep + 1}')
                .replaceAll('{total}', '$totalSteps'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _kRoyalBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / totalSteps,
                backgroundColor: _kRoyalBlue.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(_kRoyalBlue),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _config ?? kUniversalWizardConfigs['expert_repair']!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _goBack,
        ),
        title: Text(
          context.l10n(config.categoryKey),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildStep1(config),
                _buildStep2(config),
                _buildStep3Unified(config),
                _buildStep4(config),
              ],
            ),
          ),
          _buildBottomButton(config),
        ],
      ),
    );
  }

  Widget _buildStep1(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('wizard_step1_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('wizard_step1_desc_v5'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          ...config.step1SubTypes.map((e) {
            final selected = _state.step1SubTypeId == e.key;
            final label = context.l10n(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    if (selected) {
                      _state = _state.copyWith(step1SubTypeId: '', step1SubTypeLabel: '');
                      return;
                    }
                    _state = _state.copyWith(step1SubTypeId: e.key, step1SubTypeLabel: e.value);
                  }),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? _kRoyalBlue.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: selected ? _kRoyalBlue : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? _kRoyalBlue : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: _kRoyalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep2(UniversalWizardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('wizard_step2_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('wizard_step2_desc_v5'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ..._buildStep2FieldsByCategory(),
        ],
      ),
    );
  }

  List<Widget> _buildStep2FieldsByCategory() {
    if (_state.step1SubTypeId == 'other') {
      return [
        TextField(
          controller: _step1OtherServiceController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_service_name_label'),
            hint: context.l10n('wizard_other_service_name_hint'),
          ),
          maxLines: 2,
        ),
      ];
    }
    switch (_state.categoryKey) {
      case 'expert_cleaning':
        return _buildStep2CleaningV5();
      case 'expert_moving':
        return _buildStep2Moving();
      case 'expert_repair':
        return _buildStep2RepairV5();
      case 'expert_interior':
        return _buildStep2Interior();
      case 'expert_business':
        return _buildStep2Business();
      case 'expert_beauty':
        return _buildStep2BeautyV5();
      case 'expert_tutoring':
        return _buildStep2TutoringV5();
      case 'expert_events':
        return _buildStep2EventsV5();
      case 'expert_vehicle':
        return _buildStep2Vehicle();
      default:
        return _buildStep2GenericMultiSelect();
    }
  }

  List<Widget> _buildStep2CleaningV5() {
    final sub = _state.step1SubTypeId;
    return [
      if (sub == 'commercial') ...[
        TextField(
          controller: _cleaningIndustryController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_cleaning_industry_label'),
            hint: context.l10n('wizard_cleaning_industry_hint'),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (sub == 'regular_visit') ...[
        TextField(
          controller: _cleaningTargetController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_cleaning_target_label'),
            hint: context.l10n('wizard_cleaning_target_hint'),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (sub == 'bedding') ...[
        TextField(
          controller: _cleaningBeddingCountController,
          keyboardType: TextInputType.number,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_cleaning_bedding_count_label'),
            hint: context.l10n('wizard_cleaning_bedding_count_hint'),
          ),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _cleaningAreaController,
        keyboardType: TextInputType.text,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_cleaning_area_label'),
          hint: context.l10n('wizard_cleaning_area_hint'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n('wizard_cleaning_scale_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _outlineToggleTile(
              label: context.l10n('cleaning_size_s'),
              selected: _cleaningScale == 'S',
              onTap: () => setState(() => _cleaningScale = _cleaningScale == 'S' ? '' : 'S'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: context.l10n('cleaning_size_m'),
              selected: _cleaningScale == 'M',
              onTap: () => setState(() => _cleaningScale = _cleaningScale == 'M' ? '' : 'M'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _outlineToggleTile(
              label: context.l10n('cleaning_size_l'),
              selected: _cleaningScale == 'L',
              onTap: () => setState(() => _cleaningScale = _cleaningScale == 'L' ? '' : 'L'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStep2Moving() {
    final sub = _state.step1SubTypeId;
    if (sub == 'small') {
      final opts = [
        ('tuk', context.l10n('wizard_moving_vehicle_tuk')),
        ('1ton', context.l10n('wizard_moving_vehicle_1ton')),
        ('pickup', context.l10n('wizard_moving_vehicle_pickup')),
      ];
      return [
        Text(
          context.l10n('wizard_moving_vehicle_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
        ),
        const SizedBox(height: 10),
        for (final o in opts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _outlineToggleTile(
              label: o.$2,
              selected: _movingVehicleType == o.$1,
              onTap: () => setState(() => _movingVehicleType = _movingVehicleType == o.$1 ? '' : o.$1),
            ),
          ),
      ];
    }
    if (sub == 'home') {
      return [
        TextField(
          controller: _movingRoomCountController,
          keyboardType: TextInputType.number,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_moving_room_count_label'),
            hint: context.l10n('wizard_moving_room_count_hint'),
          ),
        ),
      ];
    }
    if (sub == 'cargo') {
      return [
        TextField(
          controller: _weightKgController,
          keyboardType: TextInputType.number,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_delivery_weight_label'),
            hint: context.l10n('wizard_moving_cargo_weight_hint'),
          ),
        ),
      ];
    }
    return [];
  }

  List<Widget> _buildStep2RepairV5() {
    const brands = [
      ('Samsung', 'wizard_brand_samsung'),
      ('LG', 'wizard_brand_lg'),
      ('Panasonic', 'wizard_brand_panasonic'),
      ('Chinese', 'wizard_brand_chinese'),
      ('Other', 'wizard_brand_other'),
    ];
    return [
      Text(
        context.l10n('wizard_repair_brand_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: brands
            .map(
              (b) => ChoiceChip(
                label: Text(context.l10n(b.$2)),
                selected: _repairBrand == b.$1,
                onSelected: (_) => setState(() => _repairBrand = _repairBrand == b.$1 ? '' : b.$1),
                selectedColor: _kRoyalBlue.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _repairBrand == b.$1 ? _kRoyalBlue : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _repairSymptomMemoController,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_repair_symptom_memo_label'),
          hint: context.l10n('wizard_repair_symptom_memo_hint'),
        ),
        minLines: 4,
        maxLines: 8,
      ),
    ];
  }

  List<Widget> _buildStep2Interior() {
    const parts = [
      'wizard_interior_living',
      'wizard_interior_bath',
      'wizard_interior_kitchen',
      'wizard_interior_balcony',
    ];
    return [
      Text(
        context.l10n('wizard_interior_parts_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      for (final p in parts)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(p),
            selected: _interiorParts.contains(p),
            onTap: () => setState(() {
              if (_interiorParts.contains(p)) {
                _interiorParts.remove(p);
              } else {
                _interiorParts.add(p);
              }
            }),
          ),
        ),
      if (_state.step1SubTypeId == 'remodel') ...[
        const SizedBox(height: 12),
        TextField(
          controller: _interiorBudgetController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_interior_budget_label'),
            hint: context.l10n('wizard_interior_budget_hint'),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildStep2Business() {
    const langs = [
      'lang_ko',
      'lang_lo',
      'lang_en',
      'wizard_lang_zh',
    ];
    return [
      Text(
        context.l10n('wizard_business_lang_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      for (final k in langs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(k),
            selected: _businessLangs.contains(k),
            onTap: () => setState(() {
              if (_businessLangs.contains(k)) {
                _businessLangs.remove(k);
              } else {
                _businessLangs.add(k);
              }
            }),
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _documentTypeController,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_business_doc_type_label'),
          hint: context.l10n('wizard_business_doc_type_hint'),
        ),
      ),
    ];
  }

  List<Widget> _buildStep2BeautyV5() {
    const options = [
      'wizard_beauty_massage',
      'wizard_beauty_option_nail',
      'wizard_beauty_option_cut',
      'wizard_beauty_option_care',
      'wizard_beauty_option_makeup',
    ];
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(o),
            selected: _step2Selections.contains(o),
            onTap: () => setState(() {
              if (_step2Selections.contains(o)) {
                _step2Selections.remove(o);
              } else {
                _step2Selections.add(o);
              }
            }),
          ),
        ),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_beauty_other_hint'),
          ),
          maxLines: 2,
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        controller: _beautyPeopleController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_beauty_people_label'),
          hint: context.l10n('wizard_beauty_people_hint'),
        ),
      ),
    ];
  }

  List<Widget> _buildStep2TutoringV5() {
    const levels = [
      'wizard_level_elem',
      'wizard_level_mid',
      'wizard_level_high',
      'wizard_level_adult',
    ];
    return [
      Text(
        context.l10n('wizard_tutoring_subject_from_step1'),
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
      const SizedBox(height: 6),
      if (_state.step1SubTypeLabel.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            context.l10n(_state.step1SubTypeLabel),
            style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
        ),
      Text(
        context.l10n('wizard_tutoring_level_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      for (final l in levels)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(l),
            selected: _tutoringLevels.contains(l),
            onTap: () => setState(() {
              if (_tutoringLevels.contains(l)) {
                _tutoringLevels.remove(l);
              } else {
                _tutoringLevels.add(l);
              }
            }),
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _tutorGoalController,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_learning_goal_label'),
          hint: context.l10n('wizard_learning_goal_hint'),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 10),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected)
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_tutoring_other_hint'),
          ),
          maxLines: 2,
        ),
    ];
  }

  List<Widget> _buildStep2EventsV5() {
    return [
      Text(
        context.l10n('wizard_events_kind_from_step1'),
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
      const SizedBox(height: 8),
      if (_state.step1SubTypeLabel.isNotEmpty)
        Text(
          context.l10n(_state.step1SubTypeLabel),
          style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
        ),
      const SizedBox(height: 20),
      TextField(
        controller: _eventPeopleController,
        keyboardType: TextInputType.number,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_event_people_label'),
          hint: context.l10n('wizard_event_people_hint'),
        ),
      ),
    ];
  }

  List<Widget> _buildStep2Vehicle() {
    const syms = [
      'wizard_vehicle_sym_engine',
      'wizard_vehicle_sym_tire',
      'wizard_vehicle_sym_accident',
      'wizard_vehicle_sym_electrical',
    ];
    return [
      TextField(
        controller: _vehicleBrandController,
        decoration: _outlineFieldDecoration(
          context.l10n('wizard_vehicle_brand_label'),
          hint: context.l10n('wizard_vehicle_brand_hint'),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        context.l10n('wizard_vehicle_symptom_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
      ),
      const SizedBox(height: 10),
      for (final s in syms)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(s),
            selected: _vehicleSymptoms.contains(s),
            onTap: () => setState(() {
              if (_vehicleSymptoms.contains(s)) {
                _vehicleSymptoms.remove(s);
              } else {
                _vehicleSymptoms.add(s);
              }
            }),
          ),
        ),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected)
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(
            context.l10n('wizard_other_direct_input_label'),
            hint: context.l10n('wizard_vehicle_other_hint'),
          ),
          maxLines: 2,
        ),
    ];
  }

  List<Widget> _buildStep2GenericMultiSelect() {
    const options = ['wizard_generic_option_1', 'wizard_generic_option_2', 'wizard_generic_option_3'];
    return [
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _outlineToggleTile(
            label: context.l10n(o),
            selected: _step2Selections.contains(o),
            onTap: () => setState(() {
              if (_step2Selections.contains(o)) {
                _step2Selections.remove(o);
              } else {
                _step2Selections.add(o);
              }
            }),
          ),
        ),
      _outlineToggleTile(
        label: context.l10n('symptom_other'),
        selected: _step2OtherSelected,
        onTap: () => setState(() {
          _step2OtherSelected = !_step2OtherSelected;
          if (!_step2OtherSelected) _step2OtherController.clear();
        }),
      ),
      if (_step2OtherSelected) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _step2OtherController,
          decoration: _outlineFieldDecoration(context.l10n('wizard_other_direct_input_label')),
          maxLines: 2,
        ),
      ],
    ];
  }

  Widget _buildStep3Unified(UniversalWizardConfig config) {
    const slots = 5;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('wizard_depth3_section_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('wizard_depth3_section_desc'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Text(
            _photoPromptForCategory(),
            style: const TextStyle(fontWeight: FontWeight.w600, color: _kRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('wizard_photo_upload_max').replaceAll('{n}', '$slots'),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImagesFromGallery(maxCount: slots),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.l10n('wizard_photo_pick_gallery')),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kRoyalBlue,
                    side: const BorderSide(color: _kRoyalBlue, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImageFromCamera(maxCount: slots),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(context.l10n('wizard_photo_pick_camera')),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kRoyalBlue,
                    side: const BorderSide(color: _kRoyalBlue, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(slots, (i) {
              final hasPhoto = i < _pickedImages.length;
              final image = hasPhoto ? _pickedImages[i] : null;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kRoyalBlue.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: hasPhoto
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: kIsWeb
                                ? Image.network(image!.path, fit: BoxFit.cover)
                                : Image.file(File(image!.path), fit: BoxFit.cover),
                          )
                        : Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade600, size: 34),
                  ),
                  if (hasPhoto)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: InkWell(
                        onTap: () => _removePickedImageAt(i),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kRoyalBlue, width: 1.2),
                          ),
                          child: const Icon(Icons.close, size: 16, color: _kRoyalBlue),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          if (_state.categoryKey == 'expert_moving') ...[
            TextField(
              controller: _d3MovingFromController,
              decoration: _outlineFieldDecoration(
                context.l10n('wizard_depth3_from_label'),
                hint: context.l10n('wizard_depth3_from_hint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _d3MovingToController,
              decoration: _outlineFieldDecoration(
                context.l10n('wizard_depth3_to_label'),
                hint: context.l10n('wizard_depth3_to_hint'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _d3LandmarkController,
            decoration: _outlineFieldDecoration(
              context.l10n('wizard_depth3_landmark_label'),
              hint: context.l10n('wizard_depth3_landmark_hint'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _useCurrentGps,
            icon: const Icon(Icons.my_location),
            label: Text(context.l10n('wizard_depth3_use_gps_button')),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kRoyalBlue,
              side: const BorderSide(color: _kRoyalBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
          if (_state.step3Lat != null && _state.step3Lng != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.l10n('wizard_depth3_gps_coords').replaceAll('{lat}', '${_state.step3Lat}').replaceAll('{lng}', '${_state.step3Lng}'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            context.l10n('wizard_depth3_schedule_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickPreferredDate,
                  child: Text(
                    _state.preferredDateStr.isEmpty
                        ? context.l10n('wizard_depth3_pick_date')
                        : _state.preferredDateStr,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickPreferredTime,
                  child: Text(
                    _state.preferredTimeStr.isEmpty
                        ? context.l10n('wizard_depth3_pick_time')
                        : _state.preferredTimeStr,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n('wizard_schedule_urgency'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _state.scheduleIsUrgent
                    ? context.l10n('wizard_schedule_urgent')
                    : context.l10n('wizard_schedule_normal'),
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
              ),
              Switch.adaptive(
                value: _state.scheduleIsUrgent,
                onChanged: (v) => setState(() => _state = _state.copyWith(scheduleIsUrgent: v)),
                activeThumbColor: Colors.white,
                activeTrackColor: _kRoyalBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _d3MemoController,
            decoration: InputDecoration(
              labelText: context.l10n('wizard_extra_request_label'),
              hintText: context.l10n('wizard_extra_request_hint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(UniversalWizardConfig config) {
    final buf = StringBuffer();
    final d2 = _buildDepth2Map();
    d2.forEach((k, v) => buf.writeln('$k: $v'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('wizard_summary_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n('wizard_step4_desc_v5'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          _summaryRow(context.l10n('wizard_summary_category'), context.l10n(config.categoryKey)),
          _summaryRow(
            context.l10n('wizard_summary_subtype'),
            _state.step1SubTypeLabel.isEmpty ? '' : context.l10n(_state.step1SubTypeLabel),
          ),
          _summaryRow(context.l10n('wizard_summary_depth2'), buf.toString().trim()),
          _summaryRow(
            context.l10n('wizard_summary_location'),
            _state.categoryKey == 'expert_moving'
                ? '${context.l10n('wizard_depth3_from_label')}: ${_d3MovingFromController.text}\n'
                    '${context.l10n('wizard_depth3_to_label')}: ${_d3MovingToController.text}\n'
                    '${context.l10n('wizard_depth3_landmark_label')}: ${_d3LandmarkController.text}'
                : _d3LandmarkController.text,
          ),
          if (_state.step3Lat != null)
            _summaryRow(
              'GPS',
              '${_state.step3Lat}, ${_state.step3Lng}',
            ),
          _summaryRow(
            context.l10n('wizard_summary_schedule'),
            '${_state.preferredDateStr} ${_state.preferredTimeStr} '
                '(${_state.scheduleIsUrgent ? context.l10n('wizard_schedule_urgent') : context.l10n('wizard_schedule_normal')})',
          ),
          _summaryRow(context.l10n('wizard_summary_photos'), '${_state.step3PhotoPaths.length}${context.l10n('wizard_summary_photos_unit')}'),
          if (_d3MemoController.text.trim().isNotEmpty)
            _summaryRow(context.l10n('wizard_summary_note'), _d3MemoController.text.trim()),
          const SizedBox(height: 24),
          const SettlementGuideWidget(),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: _kRoyalBlue))),
        ],
      ),
    );
  }

  Widget _buildBottomButton(UniversalWizardConfig config) {
    var canProceed = false;
    switch (_currentStep) {
      case 0:
        canProceed = _canProceedStep1();
        break;
      case 1:
        canProceed = _canProceedStep2();
        break;
      case 2:
        canProceed = _canProceedStep3();
        break;
      case 3:
        canProceed = _canProceedStep4();
        break;
    }
    final isLast = _currentStep == totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: (_isSubmitting || !canProceed)
                ? null
                : () {
                    // ignore: avoid_print
                    print('[BUTTON] 버튼 클릭됨');
                    _goNext();
                  },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kRoyalBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              side: BorderSide(color: canProceed ? _kRoyalBlue : Colors.grey.shade400, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(isLast ? context.t('apply_final') : context.t('next_step')),
          ),
        ),
      ),
    );
  }
}
