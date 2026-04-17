// =============================================================================
// v5.1: ?좊땲踰꾩꽕 4?④퀎 ?꾩?????Storage URL ???쨌 D2 ?ㅺ퀎??諛섏쁺
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
  String _movingFloorFrom = '';
  String _movingFloorTo = '';
  String _movingElevator = '';
  String _movingHouseType = '';
  String _movingDistance = '';
  final Set<String> _movingCargoTypes = {};

  final TextEditingController _cleaningAreaController = TextEditingController();
  String _cleaningScale = '';
  final TextEditingController _cleaningTargetController = TextEditingController();
  final TextEditingController _cleaningIndustryController = TextEditingController();
  final TextEditingController _cleaningBeddingCountController = TextEditingController();
  String _cleaningHouseType = '';
  String _cleaningRoomCount = '';
  String _cleaningBathroomCount = '';
  String _cleaningVisitCycle = '';
  String _cleaningBeddingType = '';
  String _cleaningApplianceCount = '';
  final Set<String> _cleaningApplianceTypes = {};

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
    // ?꾪솕踰덊샇 濡쒓렇?몃쭔 ?듦낵 (?듬챸 濡쒓렇?몄? ?듦낵 遺덇?)
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) return;
    // ?붿씠?몃━?ㅽ듃 濡쒓렇???뺤씤 (whitelistDisplayPhoneNotifier??媛믪씠 ?덉쑝硫??듦낵)
    final whitePhone = whitelistDisplayPhoneNotifier.value?.trim() ?? '';
    if (whitePhone.isNotEmpty) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(kStaticUiTripleByMessageKey['login_required_title']?[
          Localizations.localeOf(context).languageCode.startsWith('ko') ? 'ko' :
          Localizations.localeOf(context).languageCode.startsWith('lo') ? 'lo' : 'en'
        ] ?? '로그인이 필요합니다'),
        content: Text(kStaticUiTripleByMessageKey['login_required_content']?[
          Localizations.localeOf(context).languageCode.startsWith('ko') ? 'ko' :
          Localizations.localeOf(context).languageCode.startsWith('lo') ? 'lo' : 'en'
        ] ?? '서비스를 이용하려면 전화번호로 로그인해 주세요.'),
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
            child: Text(kStaticUiTripleByMessageKey['login_required_btn']?[
              Localizations.localeOf(context).languageCode.startsWith('ko') ? 'ko' :
              Localizations.localeOf(context).languageCode.startsWith('lo') ? 'lo' : 'en'
            ] ?? '로그인하기'),
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
    if (_state.step1SubTypeId == 'other' &&
        _state.categoryKey != 'expert_moving') {
      return _step1OtherServiceController.text.trim().isNotEmpty;
    }
    switch (_state.categoryKey) {
      case 'expert_moving':
        final sub = _state.step1SubTypeId;
        if (sub == 'small') return _movingVehicleType.isNotEmpty;
        if (sub == 'home') return _movingRoomCountController.text.trim().isNotEmpty;
        if (sub == 'cargo') return _movingCargoTypes.isNotEmpty;
        return true;
      case 'expert_cleaning':
        final hasBase =
            _cleaningAreaController.text.trim().isNotEmpty || _cleaningScale.isNotEmpty;
        if (!hasBase) return false;
        final sub = _state.step1SubTypeId;
        if (sub == 'restaurant_cafe') return _cleaningIndustryController.text.trim().isNotEmpty;
        if (sub == 'regular_visit') return _cleaningTargetController.text.trim().isNotEmpty;
        if (sub == 'bedding') return _cleaningBeddingCountController.text.trim().isNotEmpty;
        return true;
      case 'expert_repair':
        if (_state.step1SubTypeId == 'appliance') {
          return _repairBrand.isNotEmpty && _step2Selections.isNotEmpty;
        }
        if (_state.step1SubTypeId == 'other') {
          return _step1OtherServiceController.text.trim().isNotEmpty;
        }
        return _repairSymptomMemoController.text.trim().isNotEmpty;
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

    if (_state.categoryKey == 'expert_moving') {
      return _d3MovingFromController.text.trim().isNotEmpty &&
          _d3MovingToController.text.trim().isNotEmpty;
    }

    final hasPin = _state.step3Lat != null && _state.step3Lng != null;
    final hasLandmark = _d3LandmarkController.text.trim().isNotEmpty;
    if (!hasPin && !hasLandmark) return false;

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

  /// 湲됯뎄 [TranslationMapper]? ?숈씪??4?щ’(title/location/salary/detail)?쇰줈 ?붿빟 臾몄옄?댁쓣 臾띕뒗??
  /// Step 4?먮뒗 ?몄텧?섏? ?딄퀬, [ _submit ]?먯꽌留?踰덉뿭???ъ슜?쒕떎.
  Map<String, String> _wizardTranslationInput(UniversalWizardConfig config) {
    final d2 = _buildDepth2Map();
    final depth2Str = d2.entries
        .map((entry) => _depth2DisplayLine(entry.key, entry.value))
        .where((line) => line.trim().isNotEmpty)
        .join('\n')
        .trim();

    final locStr = _state.categoryKey == 'expert_moving'
        ? '${context.l10n('wizard_depth3_from_label')}: ${_d3MovingFromController.text}\n'
            '${context.l10n('wizard_depth3_to_label')}: ${_d3MovingToController.text}\n'
            '${context.l10n('wizard_depth3_landmark_label')}: ${_d3LandmarkController.text}'
        : _d3LandmarkController.text;

    final titleStr = [
      context.l10n(config.categoryKey),
      if (_state.step1SubTypeLabel.isNotEmpty) context.l10n(_state.step1SubTypeLabel),
    ].join(' 쨌 ');

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
          'houseType': _cleaningHouseType,
          'roomCount': _cleaningRoomCount,
          'bathroomCount': _cleaningBathroomCount,
          if (_state.step1SubTypeId == 'restaurant_cafe')
            'industry': _cleaningIndustryController.text.trim(),
          if (_state.step1SubTypeId == 'regular_visit') ...{
            'target': _cleaningTargetController.text.trim(),
            'visitCycle': _cleaningVisitCycle,
          },
          if (_state.step1SubTypeId == 'bedding') ...{
            'beddingType': _cleaningBeddingType,
            'beddingCount': _cleaningBeddingCountController.text.trim(),
          },
          if (_state.step1SubTypeId == 'appliance') ...{
            'applianceTypes': _cleaningApplianceTypes.toList(),
            'applianceCount': _cleaningApplianceCount,
          },
          if (_step2OtherSelected)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_moving':
        return {
          'fromLandmark': _d3MovingFromController.text.trim(),
          'toLandmark': _d3MovingToController.text.trim(),
          'vehicleType': _movingVehicleType,
          'houseType': _movingHouseType,
          'roomCount': _movingRoomCountController.text.trim(),
          'floorFrom': _movingFloorFrom,
          'floorTo': _movingFloorTo,
          'elevator': _movingElevator,
          if (_state.step1SubTypeId == 'cargo') ...{
            'cargoTypes': _movingCargoTypes.toList(),
            'weightKg': _weightKgController.text.trim(),
            'distance': _movingDistance,
          },
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

  String _currentLangCode() {
    final raw = Localizations.localeOf(context).languageCode.toLowerCase();
    if (raw.startsWith('ko')) return 'ko';
    if (raw.startsWith('lo')) return 'lo';
    return 'en';
  }

  String _tripleUiText(String key, {required String fallback}) {
    final lang = _currentLangCode();
    return kStaticUiTripleByMessageKey[key]?[lang] ?? fallback;
  }

  String _depth2DisplayLine(String key, dynamic value) {
    final rawValue = value is List
        ? value.map((e) => '$e').where((e) => e.trim().isNotEmpty).join(', ')
        : '$value';
    final trimmedValue = rawValue.trim();

    switch (key) {
      case 'areaOrSize':
        return '${_tripleUiText('area_or_size', fallback: '硫댁쟻 / ?ш린')}: $trimmedValue';
      case 'scale':
        final normalized = trimmedValue.toUpperCase();
        if (normalized == 'S') {
          return _tripleUiText('scale_small', fallback: '?뚰삎 (S)');
        }
        if (normalized == 'M') {
          return _tripleUiText('scale_medium', fallback: '以묓삎 (M)');
        }
        if (normalized == 'L') {
          return _tripleUiText('scale_large', fallback: '???(L)');
        }
        return trimmedValue;
      default:
        return '$key: $trimmedValue';
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    // ignore: avoid_print
    print('[SUBMIT] ?쒖옉');

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
          print('[SUBMIT] Firebase 鍮꾪솢?????ъ쭊 ?놁씠 ?좎껌 怨꾩냽');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n('wizard_need_firebase_for_photos'))),
            );
          }
          photoUrls = <String>[];
        } else {
          // ignore: avoid_print
          print('[SUBMIT] ?곌껐 ?뺤씤 ?쒖옉');
          List<ConnectivityResult> conn = <ConnectivityResult>[];
          try {
            conn = await Connectivity()
                .checkConnectivity()
                .timeout(const Duration(seconds: 30));
          } on TimeoutException catch (e) {
            if (kDebugMode) debugPrint('UniversalWizard: ?곌껐 ?뺤씤 ??꾩븘?? $e');
            conn = <ConnectivityResult>[];
          } on Object catch (e, st) {
            if (kDebugMode) {
              debugPrint('UniversalWizard: ?곌껐 ?뺤씤 ?ㅽ뙣: $e');
              debugPrint('$st');
            }
            conn = <ConnectivityResult>[];
          }
          final online = conn.any((e) =>
              e == ConnectivityResult.mobile ||
              e == ConnectivityResult.wifi ||
              e == ConnectivityResult.ethernet);
          // ignore: avoid_print
          print('[SUBMIT] ?곌껐 ?뺤씤 ?꾨즺 (online=$online)');
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
                            '?ъ쭊 ?낅줈??以?..',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
            try {
              // ignore: avoid_print
              print('[SUBMIT] ?ъ쭊?낅줈???쒖옉');
              photoUrls = await uploadExpertRequestImagesFromXFiles(
                files: _pickedImages,
                userId: uid,
              ).timeout(const Duration(seconds: 30));
              // ignore: avoid_print
              print('[SUBMIT] ?ъ쭊?낅줈??寃곌낵: ${photoUrls.length}媛?URL');
            } on TimeoutException catch (e) {
              if (kDebugMode) debugPrint('UniversalWizard: ?ъ쭊 ?낅줈????꾩븘?? $e');
              // ignore: avoid_print
              print('[SUBMIT] ?ъ쭊?낅줈????꾩븘????photoUrls=[] 濡?踰덉뿭쨌???怨꾩냽');
              photoUrls = <String>[];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n('wizard_upload_failed'))),
                );
              }
            } on Object catch (e, st) {
              if (kDebugMode) {
                debugPrint('UniversalWizard: ?ъ쭊 ?낅줈???ㅽ뙣: $e');
                debugPrint('$st');
              }
              // ignore: avoid_print
              print('[SUBMIT] ?ъ쭊?낅줈???ㅽ뙣 ??photoUrls=[] 濡?踰덉뿭쨌???怨꾩냽: $e');
              photoUrls = <String>[];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n('wizard_upload_failed'))),
                );
              }
            } finally {
              // ignore: avoid_print
              print('[SUBMIT] ?ъ쭊?낅줈??釉붾줉 finally (?ㅼ씠?쇰줈洹??リ린)');
              if (mounted) Navigator.of(context).pop();
            }
          } else {
            photoLocalPaths =
                _pickedImages.map((e) => e.path).where((s) => s.isNotEmpty).toList();
            // ignore: avoid_print
            print('[SUBMIT] ?ㅽ봽?쇱씤 ??濡쒖뺄 寃쎈줈 ${_pickedImages.length}嫄? ?낅줈???앸왂');
          }
        }
      } else {
        // ignore: avoid_print
        print('[SUBMIT] ?좏깮???ъ쭊 ?놁쓬 ??諛붾줈 踰덉뿭 ?④퀎');
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
                        '踰덉뿭 以?..',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // ignore: avoid_print
      print('[SUBMIT] 踰덉뿭 ?쒖옉');
      try {
        final tResult = await TranslationMapper.translateAllFieldsStrict(
          txInput,
          sourceLanguageCode: localeCode,
        ).timeout(const Duration(seconds: 30));
        wizardI18n = tResult.bundle ?? TranslationMapper.rawTripleBundleForFields(txInput);
      } on TimeoutException catch (e) {
        if (kDebugMode) debugPrint('UniversalWizard: 踰덉뿭 ??꾩븘?????먮Ц ?몃━????? $e');
      } on Object catch (e, st) {
        if (kDebugMode) {
          debugPrint('UniversalWizard: 踰덉뿭 ?ㅽ뙣 ???먮Ц ?몃━????? $e');
          debugPrint('$st');
        }
      } finally {
        if (kDebugMode) debugPrint('UniversalWizard: 踰덉뿭 ?④퀎 醫낅즺(?곹븳 30珥?');
      }
      if (translateProgressShown && mounted) {
        Navigator.of(context).pop();
      }
      // ignore: avoid_print
      print('[SUBMIT] 踰덉뿭 ?꾨즺');

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
                        '?꾨Ц媛?먭쾶 ?꾨떖 以?..',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // ignore: avoid_print
      print('[SUBMIT] Firestore ????쒖옉 (photos=${photoUrls.length}媛?');
      unawaited(
        saveExpertRequestV5OfflineFirst(body).then((_) {
          debugPrint('[SUBMIT] Firestore ????깃났 (Background)');
        }).catchError((e) {
          debugPrint('[SUBMIT ERROR] 諛깃렇?쇱슫?????以?踰붿씤 諛쒖깮: $e');
        }),
      );
      if (submitProgressShown && mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      // ignore: avoid_print
      print('[SUBMIT] ?먮윭: $e');
      rethrow;
    } finally {
      // ignore: avoid_print
      print('[SUBMIT] finally ?ㅽ뻾');
      if (mounted) setState(() => _isSubmitting = false);
    }

    // finally ?꾩쟾???앸궃 ??    debugPrint('[SUBMIT] ?좎? ?묐떟???뺣낫瑜??꾪빐 利됱떆 ?앹뾽 ?몄텧');
    if (!mounted) return;
    _showSuccessDialog();
  }

  /// ?꾨Ц媛 ?좎껌 ?꾨즺 ?앹뾽 (利됱떆 ?몄텧??
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('?좎껌 ?꾨즺', textAlign: TextAlign.center),
          content: const Text(
            '?꾨Ц媛?먭쾶 ?붿껌???깃났?곸쑝濡??꾨떖?섏뿀?듬땲??\n?좎떆留?湲곕떎?ㅼ＜?쒕㈃ ?꾨Ц媛媛 ?곕씫???쒕┰?덈떎.',
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
                child: const Text('?뺤씤'),
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
        final sub = _state.step1SubTypeId;
        if (sub == 'appliance') return _buildStep2RepairV5();
        // 전기/배관/페인트/기타는 메모 입력
        return [
          TextField(
            controller: _repairSymptomMemoController,
            onChanged: (_) => setState(() {}),
            decoration: _outlineFieldDecoration(
              context.l10n('wizard_repair_symptom_memo_label'),
              hint: context.l10n('wizard_repair_symptom_memo_hint'),
            ),
            minLines: 4,
            maxLines: 8,
          ),
        ];
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
    final lang = _currentLangCode();

    String t(String key) =>
        kStaticUiTripleByMessageKey[key]?[lang] ?? key;

    // 怨듯넻 ?꾩젽: 硫댁쟻(m짼) ?낅젰
    Widget areaField() => TextField(
          controller: _cleaningAreaController,
          keyboardType: TextInputType.number,
          decoration: _outlineFieldDecoration(
            t('cleaning_area_m2'),
            hint: t('cleaning_area_hint'),
          ),
        );

    // 怨듯넻 ?꾩젽: 洹쒕え S/M/L
    Widget scaleRow() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('wizard_cleaning_scale_title'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _outlineToggleTile(
                    label: t('cleaning_size_s'),
                    selected: _cleaningScale == 'S',
                    onTap: () => setState(
                        () => _cleaningScale = _cleaningScale == 'S' ? '' : 'S'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _outlineToggleTile(
                    label: t('cleaning_size_m'),
                    selected: _cleaningScale == 'M',
                    onTap: () => setState(
                        () => _cleaningScale = _cleaningScale == 'M' ? '' : 'M'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _outlineToggleTile(
                    label: t('cleaning_size_l'),
                    selected: _cleaningScale == 'L',
                    onTap: () => setState(
                        () => _cleaningScale = _cleaningScale == 'L' ? '' : 'L'),
                  ),
                ),
              ],
            ),
          ],
        );

    // 二쇨굅?뺥깭 ?좏깮 ?꾩젽
    Widget housingTypeRow() {
      final types = [
        ('apartment', t('cleaning_house_apartment')),
        ('villa', t('cleaning_house_villa')),
        ('detached', t('cleaning_house_detached')),
        ('officetel', t('cleaning_house_officetel')),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('cleaning_house_type'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((e) {
              final selected = _cleaningHouseType == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () =>
                    setState(() => _cleaningHouseType = selected ? '' : e.$1),
              );
            }).toList(),
          ),
        ],
      );
    }

    switch (sub) {
      // -- ?댁궗/?낆＜ 泥?냼 --
      case 'move_in':
        return [
          housingTypeRow(),
          const SizedBox(height: 12),
          areaField(),
          const SizedBox(height: 12),
          Text(t('cleaning_room_count'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            for (final n in ['1', '2', '3', '4+'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _outlineToggleTile(
                    label: n,
                    selected: _cleaningRoomCount == n,
                    onTap: () => setState(() =>
                        _cleaningRoomCount = _cleaningRoomCount == n ? '' : n),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Text(t('cleaning_bathroom_count'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            for (final n in ['1', '2', '3+'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _outlineToggleTile(
                    label: n,
                    selected: _cleaningBathroomCount == n,
                    onTap: () => setState(() => _cleaningBathroomCount =
                        _cleaningBathroomCount == n ? '' : n),
                  ),
                ),
              ),
          ]),
        ];

      // -- 二쇳깮泥?냼 --
      case 'house_cleaning':
        return [
          housingTypeRow(),
          const SizedBox(height: 12),
          areaField(),
          const SizedBox(height: 12),
          scaleRow(),
        ];

      // -- ?앸떦/移댄럹 --
      case 'restaurant_cafe':
        return [
          TextField(
            controller: _cleaningIndustryController,
            decoration: _outlineFieldDecoration(
              t('wizard_cleaning_restaurant_label'),
              hint: t('wizard_cleaning_restaurant_hint'),
            ),
          ),
          const SizedBox(height: 12),
          areaField(),
          const SizedBox(height: 12),
          scaleRow(),
        ];

      // -- ?뺢린諛⑸Ц --
      case 'regular_visit':
        return [
          Text(t('cleaning_visit_target'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('home', t('cleaning_visit_home')),
              ('office', t('cleaning_visit_office')),
              ('store', t('cleaning_visit_store')),
            ].map((e) {
              final selected = _cleaningTargetController.text == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(() => _cleaningTargetController.text =
                    selected ? '' : e.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(t('cleaning_visit_cycle'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('w1', t('cleaning_cycle_w1')),
              ('w2', t('cleaning_cycle_w2')),
              ('m2', t('cleaning_cycle_m2')),
              ('m1', t('cleaning_cycle_m1')),
            ].map((e) {
              final selected = _cleaningVisitCycle == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(() =>
                    _cleaningVisitCycle = selected ? '' : e.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          areaField(),
        ];

      // -- 移④뎄?몄쿃 --
      case 'bedding':
        return [
          Text(t('cleaning_bedding_type'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('duvet', t('cleaning_bedding_duvet')),
              ('pillow', t('cleaning_bedding_pillow')),
              ('mattress', t('cleaning_bedding_mattress')),
              ('set', t('cleaning_bedding_set')),
            ].map((e) {
              final selected = _cleaningBeddingType == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(() =>
                    _cleaningBeddingType = selected ? '' : e.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(t('cleaning_appliance_count'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            for (final n in [
              ('1', t('cleaning_count_1')),
              ('2', t('cleaning_count_2')),
              ('3+', t('cleaning_count_3plus')),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _outlineToggleTile(
                    label: n.$2,
                    selected: _cleaningBeddingCountController.text == n.$1,
                    onTap: () => setState(() =>
                        _cleaningBeddingCountController.text =
                            _cleaningBeddingCountController.text == n.$1
                                ? ''
                                : n.$1),
                  ),
                ),
              ),
          ]),
        ];

      // -- 媛?꾩껌??--
      case 'appliance':
        return [
          Text(t('cleaning_appliance_type'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('ac', t('cleaning_appliance_ac')),
              ('fridge', t('cleaning_appliance_fridge')),
              ('washer', t('cleaning_appliance_washer')),
              ('dishwasher', t('cleaning_appliance_dishwasher')),
              ('oven', t('cleaning_appliance_oven')),
              ('microwave', t('cleaning_appliance_microwave')),
            ].map((e) {
              final selected = _cleaningApplianceTypes.contains(e.$1);
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(() => selected
                    ? _cleaningApplianceTypes.remove(e.$1)
                    : _cleaningApplianceTypes.add(e.$1)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(t('cleaning_appliance_count'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            for (final n in [
              ('1', t('cleaning_count_1')),
              ('2', t('cleaning_count_2')),
              ('3+', t('cleaning_count_3plus')),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _outlineToggleTile(
                    label: n.$2,
                    selected: _cleaningApplianceCount == n.$1,
                    onTap: () => setState(() =>
                        _cleaningApplianceCount =
                            _cleaningApplianceCount == n.$1 ? '' : n.$1),
                  ),
                ),
              ),
          ]),
        ];

      // -- 湲고? --
      default:
        return [
          TextField(
            controller: _step1OtherServiceController,
            decoration: _outlineFieldDecoration(
              t('wizard_other_service_label'),
              hint: t('wizard_other_service_hint'),
            ),
          ),
          const SizedBox(height: 12),
          areaField(),
        ];
    }
  }

  List<Widget> _buildStep2Moving() {
    final sub = _state.step1SubTypeId;
    final lang = _currentLangCode();
    String t(String key) =>
        kStaticUiTripleByMessageKey[key]?[lang] ?? key;

    // 怨듯넻: 痢듭닔 ?좏깮 ?꾩젽
    Widget floorRow(String labelKey, String current, void Function(String) onSelect) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(labelKey),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            for (final f in [
              ('1', t('moving_floor_1')),
              ('2', t('moving_floor_2')),
              ('3', t('moving_floor_3')),
              ('4+', t('moving_floor_4plus')),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _outlineToggleTile(
                    label: f.$2,
                    selected: current == f.$1,
                    onTap: () => onSelect(current == f.$1 ? '' : f.$1),
                  ),
                ),
              ),
          ]),
        ],
      );
    }

    switch (sub) {
      // -- ?뚰삎 ?댁궗 --
      case 'small':
        return [
          Text(t('moving_vehicle_type'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('damas', t('moving_vehicle_damas')),
              ('labo', t('moving_vehicle_labo')),
              ('truck_1t', t('moving_vehicle_truck_1t')),
              ('truck_2t', t('moving_vehicle_truck_2t')),
            ].map((e) {
              final selected = _movingVehicleType == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(
                    () => _movingVehicleType = selected ? '' : e.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          floorRow('moving_floor_from', _movingFloorFrom,
              (v) => setState(() => _movingFloorFrom = v)),
          const SizedBox(height: 12),
          floorRow('moving_floor_to', _movingFloorTo,
              (v) => setState(() => _movingFloorTo = v)),
          const SizedBox(height: 12),
          Text(t('moving_elevator'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _outlineToggleTile(
                label: t('moving_elevator_yes'),
                selected: _movingElevator == 'yes',
                onTap: () => setState(() =>
                    _movingElevator = _movingElevator == 'yes' ? '' : 'yes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _outlineToggleTile(
                label: t('moving_elevator_no'),
                selected: _movingElevator == 'no',
                onTap: () => setState(() =>
                    _movingElevator = _movingElevator == 'no' ? '' : 'no'),
              ),
            ),
          ]),
        ];

      // -- 媛???댁궗 --
      case 'home':
        return [
          Text(t('moving_house_type'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('apartment', t('cleaning_house_apartment')),
              ('villa', t('cleaning_house_villa')),
              ('detached', t('cleaning_house_detached')),
              ('officetel', t('cleaning_house_officetel')),
            ].map((e) {
              final selected = _movingHouseType == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(
                    () => _movingHouseType = selected ? '' : e.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(t('moving_room_count'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            for (final n in ['1', '2', '3', '4+'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _outlineToggleTile(
                    label: n,
                    selected: _movingRoomCountController.text == n,
                    onTap: () => setState(() =>
                        _movingRoomCountController.text =
                            _movingRoomCountController.text == n ? '' : n),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          floorRow('moving_floor_from', _movingFloorFrom,
              (v) => setState(() => _movingFloorFrom = v)),
          const SizedBox(height: 12),
          floorRow('moving_floor_to', _movingFloorTo,
              (v) => setState(() => _movingFloorTo = v)),
          const SizedBox(height: 12),
          Text(t('moving_elevator'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _outlineToggleTile(
                label: t('moving_elevator_yes'),
                selected: _movingElevator == 'yes',
                onTap: () => setState(() =>
                    _movingElevator = _movingElevator == 'yes' ? '' : 'yes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _outlineToggleTile(
                label: t('moving_elevator_no'),
                selected: _movingElevator == 'no',
                onTap: () => setState(() =>
                    _movingElevator = _movingElevator == 'no' ? '' : 'no'),
              ),
            ),
          ]),
        ];

      // -- 吏??대컲 --
      case 'cargo':
        return [
          Text(t('moving_cargo_type'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('furniture', t('moving_cargo_furniture')),
              ('appliance', t('moving_cargo_appliance')),
              ('box', t('moving_cargo_box')),
              ('etc', t('moving_cargo_etc')),
            ].map((e) {
              final selected = _movingCargoTypes.contains(e.$1);
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(() => selected
                    ? _movingCargoTypes.remove(e.$1)
                    : _movingCargoTypes.add(e.$1)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightKgController,
            keyboardType: TextInputType.number,
            decoration: _outlineFieldDecoration(
              t('moving_weight'),
              hint: t('moving_weight_hint'),
            ),
          ),
          const SizedBox(height: 12),
          Text(t('moving_distance'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kRoyalBlue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('local', t('moving_distance_local')),
              ('city', t('moving_distance_city')),
              ('intercity', t('moving_distance_intercity')),
            ].map((e) {
              final selected = _movingDistance == e.$1;
              return _outlineToggleTile(
                label: e.$2,
                selected: selected,
                onTap: () => setState(
                    () => _movingDistance = selected ? '' : e.$1),
              );
            }).toList(),
          ),
        ];

      // -- 湲고? --
      default:
        return [
          TextField(
            controller: _step1OtherServiceController,
            decoration: _outlineFieldDecoration(
              t('wizard_other_service_label'),
              hint: t('wizard_other_service_hint'),
            ),
          ),
        ];
    }
  }

List<Widget> _buildStep2RepairV5() {
  final lang = _currentLangCode();
  String t(String key) => kStaticUiTripleByMessageKey[key]?[lang] ?? key;

  // 가전별 증상 목록
  const symptomsByAppliance = <String, List<(String, String)>>{
    'ac': [
      ('no_cold',    'symptom_ac_no_cold_air'),
      ('noise',      'symptom_ac_noise'),
      ('water_leak', 'symptom_ac_water_sound'),
      ('not_cool',   'symptom_ac_not_cool'),
      ('other',      'symptom_other'),
    ],
    'fridge': [
      ('no_cool', 'symptom_fridge_no_cool'),
      ('noise',   'symptom_fridge_noise'),
      ('door',    'symptom_fridge_door'),
      ('ice',     'symptom_fridge_ice'),
      ('other',   'symptom_other'),
    ],
    'washer': [
      ('no_spin',    'symptom_washer_no_spin'),
      ('water_leak', 'symptom_washer_water_leak'),
      ('noise',      'symptom_washer_noise'),
      ('no_power',   'symptom_washer_no_power'),
      ('other',      'symptom_other'),
    ],
    'tv': [
      ('no_display', 'symptom_tv_no_display'),
      ('no_sound',   'symptom_tv_no_sound'),
      ('no_power',   'symptom_tv_no_power'),
      ('remote',     'symptom_tv_remote'),
      ('other',      'symptom_other'),
    ],
    'water_purifier': [
      ('water_leak', 'symptom_wp_water_leak'),
      ('no_cold',    'symptom_wp_no_cold'),
      ('no_hot',     'symptom_wp_no_hot'),
      ('filter',     'symptom_wp_filter'),
      ('other',      'symptom_other'),
    ],
    'fan': [
      ('no_spin',  'symptom_fan_no_spin'),
      ('noise',    'symptom_fan_noise'),
      ('no_power', 'symptom_fan_no_power'),
      ('other',    'symptom_other'),
    ],
    'rice_cooker': [
      ('no_cook',  'symptom_rc_no_cook'),
      ('no_heat',  'symptom_rc_no_heat'),
      ('no_power', 'symptom_rc_no_power'),
      ('other',    'symptom_other'),
    ],
    'generator': [
      ('no_start',  'symptom_gen_no_start'),
      ('no_power',  'symptom_gen_no_power'),
      ('noise',     'symptom_gen_noise'),
      ('fuel_leak', 'symptom_gen_fuel_leak'),
      ('other',     'symptom_other'),
    ],
    'other': [
      ('broken',   'symptom_other_broken'),
      ('noise',    'symptom_other_noise'),
      ('no_power', 'symptom_other_no_power'),
      ('other',    'symptom_other'),
    ],
  };

  // 가전 아이콘 목록
  const applianceEmojis = <String, String>{
    'ac':            '❄️',
    'fridge':        '🧊',
    'washer':        '🫧',
    'tv':            '📺',
    'water_purifier':'💧',
    'fan':           '🌀',
    'rice_cooker':   '🍚',
    'generator':     '⚡',
    'other':         '🔧',
  };

  const applianceKeys = <String, String>{
    'ac':            'appliance_ac',
    'fridge':        'appliance_fridge',
    'washer':        'appliance_washer',
    'tv':            'appliance_tv',
    'water_purifier':'appliance_water_purifier',
    'fan':           'appliance_fan',
    'rice_cooker':   'appliance_rice_cooker',
    'generator':     'appliance_generator',
    'other':         'appliance_other',
  };

  final symptoms = symptomsByAppliance[_repairBrand] ?? [];

  return [
    // 가전 종류 선택 타이틀
    Text(
      t('appliance_select_title'),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kRoyalBlue),
    ),
    const SizedBox(height: 6),
    Text(
      t('appliance_select_desc'),
      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
    ),
    const SizedBox(height: 16),

    // 아이콘 카드 그리드
    GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: applianceKeys.entries.map((entry) {
        final id = entry.key;
        final labelKey = entry.value;
        final emoji = applianceEmojis[id] ?? '🔧';
        final selected = _repairBrand == id;
        return GestureDetector(
          onTap: () => setState(() {
            _repairBrand = selected ? '' : id;
            _repairSymptomMemoController.clear();
            _step2Selections.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? _kRoyalBlue.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _kRoyalBlue : Colors.grey.shade300,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(
                      color: _kRoyalBlue.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(
                  t(labelKey),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _kRoyalBlue : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),

    // 증상 선택 (가전 선택 후 애니메이션 등장)
    AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _repairBrand.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                // 선택된 가전 요약 태그
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kRoyalBlue,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        applianceEmojis[_repairBrand] ?? '🔧',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t(applianceKeys[_repairBrand] ?? 'appliance_other'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t('request_step1_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kRoyalBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('request_step1_desc'),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                ...symptoms.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _outlineToggleTile(
                    label: t(e.$2),
                    selected: _step2Selections.contains(e.$1),
                    onTap: () => setState(() {
                      if (_step2Selections.contains(e.$1)) {
                        _step2Selections.remove(e.$1);
                      } else {
                        _step2Selections.add(e.$1);
                      }
                    }),
                  ),
                )),
              ],
            ),
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
    final d2 = _buildDepth2Map();
    final depth2Display = d2.entries
        .map((entry) => _depth2DisplayLine(entry.key, entry.value))
        .where((line) => line.trim().isNotEmpty)
        .join('\n')
        .trim();
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
          _summaryRow(context.l10n('wizard_summary_depth2'), depth2Display),
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
                    print('[BUTTON] 버튼 클릭');
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

