// =============================================================================
// v5.1: ?좊땲踰꾩꽕 4?④퀎 ?꾩?????Storage URL ???쨌 D2 ?ㅺ퀎??諛섏쁺
// Firestore: artifacts/{projectId}/public/data/requests
// =============================================================================

import 'dart:async' show TimeoutException, unawaited;

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
import 'steps/wizard_step1.dart';
import 'steps/wizard_step2_cleaning.dart';
import 'steps/wizard_step2_business.dart';
import 'steps/wizard_step2_beauty.dart';
import 'steps/wizard_step2_interior.dart';
import 'steps/wizard_step2_moving.dart';
import 'steps/wizard_step2_repair.dart';
import 'steps/wizard_step2_tutoring.dart';
import 'steps/wizard_step2_events.dart';
import 'steps/wizard_step2_vehicle.dart';
import 'steps/wizard_step2_generic.dart';
import 'steps/wizard_common.dart';
import 'steps/wizard_step3.dart';
import 'steps/wizard_step4.dart';
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
  // 필수항목 검증 오류 표시용
  final Set<String> _fieldErrors = {};

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
    _d3LandmarkController.addListener(() {
      if (_d3LandmarkController.text.trim().isNotEmpty) {
        setState(() => _fieldErrors.remove('landmark'));
      }
    });
    _d3MovingFromController.addListener(() {
      if (_d3MovingFromController.text.trim().isNotEmpty) {
        setState(() => _fieldErrors.remove('movingFrom'));
      }
    });
    _d3MovingToController.addListener(() {
      if (_d3MovingToController.text.trim().isNotEmpty) {
        setState(() => _fieldErrors.remove('movingTo'));
      }
    });
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

  void _onNextPressed() {
    final errors = _validateCurrentStep();
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors
        ..clear()
        ..addAll(errors));
      return;
    }
    setState(() => _fieldErrors.clear());
    _goNext();
  }

  Set<String> _validateCurrentStep() {
    final errors = <String>{};
    switch (_currentStep) {
      case 0:
        if (!_canProceedStep1()) errors.add('step1SubType');
      case 1:
        _validateStep2(errors);
      case 2:
        _validateStep3(errors);
      case 3:
        break;
    }
    return errors;
  }

  void _validateStep2(Set<String> errors) {
    switch (_state.categoryKey) {
      case 'expert_cleaning':
        if (_cleaningAreaController.text.trim().isEmpty) {
          errors.add('cleaningArea');
        }
        break;
      case 'expert_business':
        if (_businessLangs.isEmpty) errors.add('businessLang');
        final sub = _state.step1SubTypeId;
        if (sub == 'translate_docs' || sub == 'legal_doc') {
          if (_documentTypeController.text.trim().isEmpty) {
            errors.add('documentType');
          }
        }
        break;
      case 'expert_beauty':
        if (_beautyPeopleController.text.trim().isEmpty) {
          errors.add('beautyPeople');
        }
        break;
      case 'expert_events':
        if (_eventPeopleController.text.trim().isEmpty) {
          errors.add('eventPeople');
        }
        break;
      case 'expert_vehicle':
        final sub = _state.step1SubTypeId;
        if (sub == 'car_repair' || sub == 'moto_repair') {
          if (_vehicleBrandController.text.trim().isEmpty &&
              _vehicleSymptoms.isEmpty) {
            errors.add('vehicleBrand');
          }
        }
        break;
      case 'expert_tutoring':
        if (_tutoringLevels.isEmpty && _tutorGoalController.text.trim().isEmpty) {
          errors.add('tutoringLevel');
        }
        break;
      default:
        break;
    }
  }

  void _validateStep3(Set<String> errors) {
    if (_state.preferredDateStr.isEmpty) errors.add('preferredDate');
    if (_state.preferredTimeStr.isEmpty) errors.add('preferredTime');

    final config = _config;
    if (config == null) return;

    switch (config.step3Mode) {
      case Step3LocationMode.routing:
        if (_d3MovingFromController.text.trim().isEmpty) {
          errors.add('movingFrom');
        }
        if (_d3MovingToController.text.trim().isEmpty) {
          errors.add('movingTo');
        }
        break;
      case Step3LocationMode.flexible:
        if (_state.step3ServiceMode == null) errors.add('serviceMode');
        final mode = _state.step3ServiceMode;
        if (mode != null && mode != ServiceModeChoice.remote) {
          if (_d3LandmarkController.text.trim().isEmpty &&
              _state.step3Lat == null) {
            errors.add('landmark');
          }
        }
        break;
      case Step3LocationMode.onsite:
        if (_d3LandmarkController.text.trim().isEmpty &&
            _state.step3Lat == null) {
          errors.add('landmark');
        }
        break;
    }
  }

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

    final config = _config;
    if (config == null) return {};

    String locStr;
    switch (config.step3Mode) {
      case Step3LocationMode.routing:
        locStr =
            '${context.l10n('wizard_depth3_from_label')}: ${_d3MovingFromController.text}\n'
            '${context.l10n('wizard_depth3_to_label')}: ${_d3MovingToController.text}\n'
            '${context.l10n('wizard_depth3_landmark_label')}: ${_d3LandmarkController.text}';
      case Step3LocationMode.flexible:
        final mode = _state.step3ServiceMode;
        if (mode == ServiceModeChoice.remote) {
          locStr = context.l10n('wizard_step3_mode_remote');
        } else if (mode == ServiceModeChoice.goToShop) {
          locStr =
              '${context.l10n('wizard_step3_mode_go_to_shop')}: ${_d3LandmarkController.text}';
        } else {
          locStr =
              '${context.l10n('wizard_step3_mode_visit')}: ${_d3LandmarkController.text}';
        }
      case Step3LocationMode.onsite:
        locStr = _d3LandmarkController.text;
    }

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
          'selections': _step2Selections.toList(),
          if (_step2OtherSelected)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_beauty':
        return {
          'kinds': _step2Selections.toList(),
          'people': _beautyPeopleController.text.trim(),
          if (_step2OtherController.text.trim().isNotEmpty)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_tutoring':
        return {
          'subject': _state.step1SubTypeId,
          'levels': _tutoringLevels.toList(),
          'classType': _step2Selections.toList(),
          'goal': _tutorGoalController.text.trim(),
          if (_step2OtherSelected)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_events':
        return {
          'eventKind': _state.step1SubTypeId,
          'expectedPeople': _eventPeopleController.text.trim(),
          'selections': _step2Selections.toList(),
          if (_step2OtherController.text.trim().isNotEmpty)
            'eventDetail': _step2OtherController.text.trim(),
        };
      case 'expert_vehicle':
        return {
          'brandOrModel': _vehicleBrandController.text.trim(),
          'symptoms': _vehicleSymptoms.toList(),
          'rentalOptions': _step2Selections.toList(),
          'symptomDetail': _repairSymptomMemoController.text.trim(),
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

  String _depth2DisplayLine(String key, dynamic value) {
    final lang = _currentLangCode();
    String t(String k) => kStaticUiTripleByMessageKey[k]?[lang] ?? k;

    // 빈값 필터링
    if (value == null) return '';
    final rawValue = value is List
        ? value.map((e) {
            final s = '$e'.trim();
            return kStaticUiTripleByMessageKey[s]?[lang] ?? s;
          }).where((e) => e.isNotEmpty).join(', ')
        : '$value'.trim();
    if (rawValue.isEmpty) return '';

    switch (key) {
      // ── 공통 ──────────────────────────────────
      case 'areaOrSize':
        return '${t('area_or_size')}: $rawValue';
      case 'scale':
        final n = rawValue.toUpperCase();
        if (n == 'S') return t('scale_small');
        if (n == 'M') return t('scale_medium');
        if (n == 'L') return t('scale_large');
        return rawValue;
      case 'houseType':
        return '${t('cleaning_house_type')}: ${t('cleaning_house_$rawValue')}';
      case 'roomCount':
        return '${t('cleaning_room_count')}: $rawValue';
      case 'bathroomCount':
        return '${t('cleaning_bathroom_count')}: $rawValue';
      case 'otherNote':
        return '${t('wizard_other_service_label')}: $rawValue';
      case 'customService':
        return '${t('wizard_other_service_label')}: $rawValue';

      // ── 청소 ──────────────────────────────────
      case 'industry':
        return '${t('wizard_cleaning_restaurant_label')}: $rawValue';
      case 'target':
        return '${t('cleaning_visit_target')}: $rawValue';
      case 'visitCycle':
        return '${t('cleaning_visit_cycle')}: $rawValue';
      case 'beddingType':
        return '${t('cleaning_bedding_type')}: $rawValue';
      case 'beddingCount':
        return '${t('cleaning_appliance_count')}: $rawValue';
      case 'applianceTypes':
        return '${t('cleaning_appliance_type')}: $rawValue';
      case 'applianceCount':
        return '${t('cleaning_appliance_count')}: $rawValue';

      // ── 이사 ──────────────────────────────────
      case 'vehicleType':
        return '${t('moving_vehicle_type')}: $rawValue';
      case 'floorFrom':
        return '${t('moving_floor_from')}: $rawValue';
      case 'floorTo':
        return '${t('moving_floor_to')}: $rawValue';
      case 'elevator':
        return '${t('moving_elevator')}: $rawValue';
      case 'cargoTypes':
        return '${t('moving_cargo_type')}: $rawValue';
      case 'weightKg':
        return '${t('moving_weight')}: $rawValue kg';
      case 'distance':
        return '${t('moving_distance')}: $rawValue';
      case 'fromLandmark':
        return '${t('moving_floor_from')}: $rawValue';
      case 'toLandmark':
        return '${t('moving_floor_to')}: $rawValue';

      // ── 가전수리 ───────────────────────────────
      case 'brand':
        final brandLabel = kStaticUiTripleByMessageKey['appliance_$rawValue']?[lang];
        return '${t('appliance_select_title')}: ${brandLabel ?? rawValue}';
      case 'symptomDetail':
        if (rawValue.isEmpty) return '';
        final memoLabel = _state.categoryKey == 'expert_vehicle'
            ? 'vehicle_symptom_memo_label'
            : 'wizard_repair_symptom_memo_label';
        return '${t(memoLabel)}: $rawValue';

      // ── 인테리어 ───────────────────────────────
      case 'parts':
        return '${t('interior_housing_type')}: $rawValue';
      case 'budgetRange':
        return '${t('interior_budget_label')}: $rawValue';

      // ── 비즈니스·번역 ──────────────────────────
      case 'languages':
        return '${t('wizard_business_lang_title')}: $rawValue';
      case 'documentKind':
        return '${t('wizard_business_doc_type_label')}: $rawValue';
      case 'selections':
        if (rawValue.isEmpty) return '';
        final lang = _currentLangCode();
        String t(String k) => kStaticUiTripleByMessageKey[k]?[lang] ?? k;
        return '${t('wizard_step2_title')}: $rawValue';

      // ── 미용 ───────────────────────────────────
      case 'kinds':
        if (rawValue.isEmpty) return '';
        return '${t('beauty_visit_type_title')}: $rawValue';
      case 'people':
        return '${t('wizard_beauty_people_label')}: $rawValue';

      // ── 과외·레슨 ──────────────────────────────
      case 'subject':
        if (rawValue.isEmpty) return '';
        final subjectKey = 'sub_tutor_$rawValue';
        final subjectLabel = kStaticUiTripleByMessageKey[subjectKey]?[lang]
            ?? kStaticUiTripleByMessageKey[rawValue]?[lang];
        return subjectLabel != null
            ? '${t('wizard_tutoring_subject_from_step1')}: $subjectLabel'
            : '';
      case 'classType':
        if (rawValue.isEmpty) return '';
        return '${t('tutor_class_type_title')}: $rawValue';
      case 'levels':
        if (rawValue.isEmpty) return '';
        return '${t('wizard_tutoring_level_title')}: $rawValue';
      case 'goal':
        if (rawValue.isEmpty) return '';
        return '${t('wizard_learning_goal_label')}: $rawValue';

      // ── 이벤트 ────────────────────────────────
      case 'eventKind':
        if (rawValue.isEmpty) return '';
        final eventLabel = kStaticUiTripleByMessageKey['sub_events_$rawValue']?[lang]
            ?? kStaticUiTripleByMessageKey[rawValue]?[lang];
        return eventLabel != null
            ? '${t('wizard_events_kind_from_step1')}: $eventLabel'
            : '';
      case 'expectedPeople':
        if (rawValue.isEmpty) return '';
        return '${t('wizard_event_people_label')}: $rawValue';
      case 'eventDetail':
        if (rawValue.isEmpty) return '';
        return '${t('events_detail_label')}: $rawValue';

      // ── 자동차 ────────────────────────────────
      case 'brandOrModel':
        if (rawValue.isEmpty) return '';
        return '${t('wizard_vehicle_brand_label')}: $rawValue';
      case 'symptoms':
        if (rawValue.isEmpty) return '';
        return '${t('wizard_vehicle_symptom_title')}: $rawValue';
      case 'rentalOptions':
        if (rawValue.isEmpty) return '';
        return '${t('vehicle_rental_duration_title')}: $rawValue';

      default:
        return rawValue.isNotEmpty ? rawValue : '';
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

      final step3Mode = _config?.step3Mode ?? Step3LocationMode.onsite;
      final serviceMode = _state.step3ServiceMode;
      final location = <String, dynamic>{
        'lat': _state.step3Lat ?? 0.0,
        'lng': _state.step3Lng ?? 0.0,
        'landmark': _d3LandmarkController.text.trim(),
        // 서비스 방식 저장 (flexible 모드)
        if (step3Mode == Step3LocationMode.flexible && serviceMode != null)
          'serviceMode': switch (serviceMode) {
            ServiceModeChoice.remote => 'remote',
            ServiceModeChoice.visit => 'visit',
            ServiceModeChoice.goToShop => 'goToShop',
          },
        // 이동형(이사): 출발지 + 도착지
        if (step3Mode == Step3LocationMode.routing) ...{
          'fromLandmark': _d3MovingFromController.text.trim(),
          'toLandmark': _d3MovingToController.text.trim(),
        },
        // 원격 선택 시 위치 초기화
        if (step3Mode == Step3LocationMode.flexible &&
            serviceMode == ServiceModeChoice.remote) ...{
          'lat': 0.0,
          'lng': 0.0,
          'landmark': '',
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
    final lang = _currentLangCode();
    String t(String key) => kStaticUiTripleByMessageKey[key]?[lang] ?? key;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            t('request_success_title'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            t('request_success_message'),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  SearchTriggerBus.trigger();
                  Navigator.of(dialogContext).pop();
                  if (mounted) Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRoyalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(t('confirm')),
              ),
            ),
          ],
        );
      },
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
    setState(() {
      _state = _state.copyWith(preferredDateStr: '$y-$m-$day');
      _fieldErrors.remove('preferredDate');
    });
  }

  Future<void> _pickPreferredTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null || !mounted) return;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    setState(() {
      _state = _state.copyWith(preferredTimeStr: '$h:$m');
      _fieldErrors.remove('preferredTime');
    });
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
    return WizardStep1(
      config: config,
      state: _state,
      onSubTypeSelected: (id, label) {
        setState(() {
          _state = _state.copyWith(
            step1SubTypeId: id,
            step1SubTypeLabel: label,
          );
        });
      },
      l10n: context.l10n,
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
          onChanged: (_) => setState(() {}),
          decoration: wizardOutlineFieldDecoration(
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
            decoration: wizardOutlineFieldDecoration(
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
    return [
      WizardStep2Cleaning(
        subTypeId: _state.step1SubTypeId,
        cleaningScale: _cleaningScale,
        cleaningHouseType: _cleaningHouseType,
        cleaningRoomCount: _cleaningRoomCount,
        cleaningBathroomCount: _cleaningBathroomCount,
        cleaningVisitCycle: _cleaningVisitCycle,
        cleaningBeddingType: _cleaningBeddingType,
        cleaningApplianceCount: _cleaningApplianceCount,
        cleaningApplianceTypes: _cleaningApplianceTypes,
        areaController: _cleaningAreaController,
        targetController: _cleaningTargetController,
        industryController: _cleaningIndustryController,
        beddingCountController: _cleaningBeddingCountController,
        otherController: _step1OtherServiceController,
        step2Selections: _step2Selections,
        currentLangCode: _currentLangCode(),
        onScaleChanged: (v) => setState(() => _cleaningScale = v),
        onHouseTypeChanged: (v) => setState(() => _cleaningHouseType = v),
        onRoomCountChanged: (v) => setState(() => _cleaningRoomCount = v),
        onBathroomCountChanged: (v) =>
            setState(() => _cleaningBathroomCount = v),
        onVisitCycleChanged: (v) => setState(() => _cleaningVisitCycle = v),
        onBeddingTypeChanged: (v) => setState(() => _cleaningBeddingType = v),
        onApplianceCountChanged: (v) =>
            setState(() => _cleaningApplianceCount = v),
        onApplianceTypeToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _cleaningApplianceTypes.remove(id);
          } else {
            _cleaningApplianceTypes.add(id);
          }
        }),
        onStateChanged: () => setState(() {
          if (_cleaningAreaController.text.trim().isNotEmpty) {
            _fieldErrors.remove('cleaningArea');
          }
        }),
        fieldErrors: _fieldErrors,
      ),
    ];
  }

  List<Widget> _buildStep2Moving() {
    return [
      WizardStep2Moving(
        subTypeId: _state.step1SubTypeId,
        movingVehicleType: _movingVehicleType,
        movingFloorFrom: _movingFloorFrom,
        movingFloorTo: _movingFloorTo,
        movingElevator: _movingElevator,
        movingHouseType: _movingHouseType,
        movingDistance: _movingDistance,
        movingCargoTypes: _movingCargoTypes,
        roomCountController: _movingRoomCountController,
        weightKgController: _weightKgController,
        otherController: _step1OtherServiceController,
        currentLangCode: _currentLangCode(),
        onVehicleTypeChanged: (v) =>
            setState(() => _movingVehicleType = v),
        onFloorFromChanged: (v) =>
            setState(() => _movingFloorFrom = v),
        onFloorToChanged: (v) =>
            setState(() => _movingFloorTo = v),
        onElevatorChanged: (v) =>
            setState(() => _movingElevator = v),
        onHouseTypeChanged: (v) =>
            setState(() => _movingHouseType = v),
        onDistanceChanged: (v) =>
            setState(() => _movingDistance = v),
        onCargoTypeToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _movingCargoTypes.remove(id);
          } else {
            _movingCargoTypes.add(id);
          }
        }),
        onStateChanged: () => setState(() {}),
      ),
    ];
  }

List<Widget> _buildStep2RepairV5() {
  return [
    WizardStep2Repair(
      repairBrand: _repairBrand,
      step2Selections: _step2Selections,
      symptomMemoController: _repairSymptomMemoController,
      currentLangCode: _currentLangCode(),
      onBrandChanged: (id) => setState(() {
        _repairBrand = id;
        _repairSymptomMemoController.clear();
        _step2Selections.clear();
      }),
      onSymptomToggled: (id, wasSelected) => setState(() {
        if (wasSelected) {
          _step2Selections.remove(id);
        } else {
          _step2Selections.add(id);
        }
      }),
    ),
  ];
}

  List<Widget> _buildStep2Interior() {
    return [
      WizardStep2Interior(
        subTypeId: _state.step1SubTypeId,
        interiorParts: _interiorParts,
        step2Selections: _step2Selections,
        budgetController: _interiorBudgetController,
        otherController: _step2OtherController,
        step1OtherController: _step1OtherServiceController,
        currentLangCode: _currentLangCode(),
        onInteriorPartToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _interiorParts.remove(id);
          } else {
            _interiorParts.add(id);
          }
        }),
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onStateChanged: () => setState(() {}),
      ),
    ];
  }

  List<Widget> _buildStep2Business() {
    return [
      WizardStep2Business(
        subTypeId: _state.step1SubTypeId,
        businessLangs: _businessLangs,
        step2Selections: _step2Selections,
        documentTypeController: _documentTypeController,
        currentLangCode: _currentLangCode(),
        l10n: context.l10n,
        onLangToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _businessLangs.remove(id);
          } else {
            _businessLangs.add(id);
          }
        }),
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onStateChanged: () => setState(() {
          if (_documentTypeController.text.trim().isNotEmpty) {
            _fieldErrors.remove('documentType');
          }
          if (_businessLangs.isNotEmpty) {
            _fieldErrors.remove('businessLang');
          }
        }),
        fieldErrors: _fieldErrors,
      ),
    ];
  }

  List<Widget> _buildStep2BeautyV5() {
    return [
      WizardStep2Beauty(
        subTypeId: _state.step1SubTypeId,
        step2Selections: _step2Selections,
        peopleController: _beautyPeopleController,
        otherController: _step2OtherController,
        currentLangCode: _currentLangCode(),
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onVisitTypeSelected: (type) => setState(() {
          final other = type == 'visit_home' ? 'visit_shop' : 'visit_home';
          _step2Selections.remove(other);
          if (_step2Selections.contains(type)) {
            _step2Selections.remove(type);
          } else {
            _step2Selections.add(type);
          }
        }),
        onStateChanged: () => setState(() {
          if (_beautyPeopleController.text.trim().isNotEmpty) {
            _fieldErrors.remove('beautyPeople');
          }
        }),
        fieldErrors: _fieldErrors,
      ),
    ];
  }

  List<Widget> _buildStep2TutoringV5() {
    return [
      WizardStep2Tutoring(
        subTypeId: _state.step1SubTypeId,
        tutoringLevels: _tutoringLevels,
        step2Selections: _step2Selections,
        goalController: _tutorGoalController,
        currentLangCode: _currentLangCode(),
        onLevelToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _tutoringLevels.remove(id);
          } else {
            _tutoringLevels.add(id);
          }
        }),
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onStateChanged: () => setState(() {
          if (_eventPeopleController.text.trim().isNotEmpty) {
            _fieldErrors.remove('eventPeople');
          }
        }),
        fieldErrors: _fieldErrors,
      ),
    ];
  }

  List<Widget> _buildStep2EventsV5() {
    return [
      WizardStep2Events(
        subTypeId: _state.step1SubTypeId,
        step2Selections: _step2Selections,
        peopleController: _eventPeopleController,
        memoController: _step2OtherController,
        currentLangCode: _currentLangCode(),
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onStateChanged: () => setState(() {
          if (_vehicleBrandController.text.trim().isNotEmpty) {
            _fieldErrors.remove('vehicleBrand');
          }
          if (_vehicleSymptoms.isNotEmpty) {
            _fieldErrors.remove('vehicleBrand');
          }
        }),
        fieldErrors: _fieldErrors,
      ),
    ];
  }

  List<Widget> _buildStep2Vehicle() {
    return [
      WizardStep2Vehicle(
        subTypeId: _state.step1SubTypeId,
        vehicleSymptoms: _vehicleSymptoms,
        step2Selections: _step2Selections,
        brandController: _vehicleBrandController,
        symptomMemoController: _repairSymptomMemoController,
        currentLangCode: _currentLangCode(),
        onSymptomToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _vehicleSymptoms.remove(id);
          } else {
            _vehicleSymptoms.add(id);
          }
        }),
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onStateChanged: () => setState(() {}),
        fieldErrors: _fieldErrors,
      ),
    ];
  }

  List<Widget> _buildStep2GenericMultiSelect() {
    return [
      WizardStep2Generic(
        step2Selections: _step2Selections,
        step2OtherSelected: _step2OtherSelected,
        otherController: _step2OtherController,
        l10n: context.l10n,
        onSelectionToggled: (id, wasSelected) => setState(() {
          if (wasSelected) {
            _step2Selections.remove(id);
          } else {
            _step2Selections.add(id);
          }
        }),
        onOtherToggled: (value) => setState(() {
          _step2OtherSelected = value;
          if (!value) _step2OtherController.clear();
        }),
        onStateChanged: () => setState(() {}),
      ),
    ];
  }

  Widget _buildStep3Unified(UniversalWizardConfig config) {
    return WizardStep3(
      state: _state,
      fieldErrors: _fieldErrors,
      step3Mode: config.step3Mode,
      pickedImages: _pickedImages,
      photoSlotCount: config.photoSlotCount,
      photoPrompt: _photoPromptForCategory(),
      l10n: context.l10n,
      onPickGallery: () => _pickImagesFromGallery(maxCount: 5),
      onPickCamera: () => _pickImageFromCamera(maxCount: 5),
      onRemoveImage: _removePickedImageAt,
      onPickDate: _pickPreferredDate,
      onPickTime: _pickPreferredTime,
      onUrgentChanged: (v) =>
          setState(() => _state = _state.copyWith(scheduleIsUrgent: v)),
      onServiceModeChanged: (choice) => setState(() {
        _state = _state.copyWith(step3ServiceMode: choice);
        if (choice != null) {
          _fieldErrors.remove('serviceMode');
        }
      }),
      landmarkController: _d3LandmarkController,
      movingFromController: _d3MovingFromController,
      movingToController: _d3MovingToController,
      memoController: _d3MemoController,
      onUseGps: _useCurrentGps,
    );
  }

  Widget _buildStep4(UniversalWizardConfig config) {
    final d2 = _buildDepth2Map();
    final depth2Display = d2.entries
        .map((entry) => _depth2DisplayLine(entry.key, entry.value))
        .where((line) => line.trim().isNotEmpty)
        .join('\n')
        .trim();
    return WizardStep4(
      config: config,
      state: _state,
      depth2Display: depth2Display,
      l10n: context.l10n,
      t: context.t,
      landmarkController: _d3LandmarkController,
      movingFromController: _d3MovingFromController,
      movingToController: _d3MovingToController,
      memoController: _d3MemoController,
    );
  }

  Widget _buildBottomButton(UniversalWizardConfig config) {
    final isLast = _currentStep == totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_currentStep == totalSteps - 1) {
                      _goNext();
                    } else {
                      _onNextPressed();
                    }
                  },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kRoyalBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              side: const BorderSide(color: _kRoyalBlue, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(isLast ? context.t('apply_final') : context.t('next_step')),
          ),
        ),
      ),
    );
  }
}

