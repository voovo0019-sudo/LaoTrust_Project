// =============================================================================
// v5.1: ?좊땲踰꾩꽕 4?④퀎 ?꾩?????Storage URL ???쨌 D2 ?ㅺ퀎??諛섏쁺
// Firestore: artifacts/{projectId}/public/data/requests
// =============================================================================

import 'dart:async' show Completer, TimeoutException, unawaited;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_localizations.dart';
import '../../core/expert_request_photo_upload.dart';
import '../../core/firebase_service.dart';
import '../../core/location_service.dart';
import '../../core/offline_first_sync.dart';
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

const _kBusinessDocChipIds = {
  'passport',
  'contract',
  'certificate',
  'medical',
  'corporate',
  'property',
  'customs',
};

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
  Completer<void>? _pendingSaveCompleter;
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
  final TextEditingController _movingCargoOtherController =
      TextEditingController();

  final TextEditingController _cleaningAreaController = TextEditingController();
  String _cleaningScale = '';
  final TextEditingController _cleaningTargetController = TextEditingController();
  final TextEditingController _cleaningIndustryController = TextEditingController();
  final TextEditingController _cleaningBeddingCountController = TextEditingController();
  String _cleaningHouseType = '';
  String _cleaningRoomCount = '';
  String _cleaningBathroomCount = '';
  String _cleaningVisitCycle = '';
  String _guesthouseSelectedArea = '';
  String _guesthouseSelectedScale = '';
  String _guesthouseSelectedFrequency = '';
  String _cleaningBeddingType = '';
  String _cleaningApplianceCount = '';
  final Set<String> _cleaningApplianceTypes = {};

  final Set<String> _tutoringSubjects = <String>{};
  final Set<String> _tutoringLevels = <String>{};
  final TextEditingController _tutorGoalController = TextEditingController();
  final TextEditingController _tutorOtherController = TextEditingController();

  final TextEditingController _eventPeopleController = TextEditingController();

  final Set<String> _interiorParts = <String>{};
  final TextEditingController _interiorBudgetController = TextEditingController();
  final TextEditingController _interiorAreaController = TextEditingController();

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
    _movingCargoOtherController.dispose();
    _cleaningAreaController.dispose();
    _cleaningTargetController.dispose();
    _cleaningIndustryController.dispose();
    _cleaningBeddingCountController.dispose();
    _tutorGoalController.dispose();
    _tutorOtherController.dispose();
    _eventPeopleController.dispose();
    _interiorBudgetController.dispose();
    _interiorAreaController.dispose();
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

  void _checkAuthAndRedirect() {
    if (!mounted) return;
    // Firebase Phone Auth 단일 로그인 체크
    if (hasRecognizedUserSession) return;
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
                '/wizard',
                <String, dynamic>{
                  'categoryKey': catKey,
                  'initialSubTypeId': subId,
                  'initialSubTypeLabel': subLabel,
                },
              );
              context.push('/login');
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

  void _resetAllInputs() {
    // GPS 좌표 초기화 (state 안에 저장되므로 별도 처리)
    _state = _state.copyWith(
      step3Lat: null,
      step3Lng: null,
      step3Landmark: '',
      step3MovingFromLandmark: '',
      step3MovingToLandmark: '',
      step3ServiceMode: null,
      preferredDateStr: '',
      preferredTimeStr: '',
      scheduleIsUrgent: false,
    );
    // Step2 공통
    _step2Selections.clear();
    _step2OtherSelected = false;
    _step2OtherController.clear();

    // 사진
    _pickedImages.clear();

    // cleaning
    _cleaningAreaController.clear();
    _cleaningScale = '';
    _cleaningHouseType = '';
    _cleaningRoomCount = '';
    _cleaningBathroomCount = '';
    _cleaningVisitCycle = '';
    _cleaningTargetController.clear();
    _cleaningIndustryController.clear();
    _cleaningBeddingCountController.clear();
    _cleaningBeddingType = '';
    _cleaningApplianceCount = '';
    _cleaningApplianceTypes.clear();
    _guesthouseSelectedArea = '';
    _guesthouseSelectedScale = '';
    _guesthouseSelectedFrequency = '';

    // moving
    _movingHouseType = '';
    _movingVehicleType = '';
    _movingDistance = '';
    _movingFloorFrom = '';
    _movingFloorTo = '';
    _movingElevator = '';
    _movingCargoTypes.clear();
    _movingRoomCountController.clear();
    _movingCargoOtherController.clear();

    // tutoring
    _tutoringLevels.clear();
    _tutorGoalController.clear();
    _tutorOtherController.clear();

    // events
    _eventPeopleController.clear();

    // interior
    _interiorParts.clear();
    _interiorBudgetController.clear();
    _interiorAreaController.clear();

    // business
    _businessLangs.clear();
    _documentTypeController.clear();

    // vehicle
    _vehicleSymptoms.clear();
    _vehicleBrandController.clear();

    // beauty
    _beautyPeopleController.clear();

    // repair
    _repairBrand = '';
    _repairSymptomMemoController.clear();

    // Step3 공통
    _d3LandmarkController.clear();
    _d3MovingFromController.clear();
    _d3MovingToController.clear();
    _d3MemoController.clear();

    // 유효성 에러
    _fieldErrors.clear();
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

  void _goNext() {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedStep1() {
    if (_config?.categoryKey == 'expert_tutoring') {
      return _tutoringSubjects.isNotEmpty;
    }
    return _state.step1SubTypeId.isNotEmpty;
  }

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
    if (_state.step1SubTypeId == 'other') {
      if (_step1OtherServiceController.text.trim().isEmpty) {
        errors.add('otherService');
      }
      return;
    }
    switch (_state.categoryKey) {
      case 'expert_cleaning':
        if (_state.step1SubTypeId == 'guesthouse') {
          if (_guesthouseSelectedArea.isEmpty) {
            errors.add('guesthouseArea');
          }
          if (_guesthouseSelectedScale.isEmpty) {
            errors.add('guesthouseScale');
          }
          if (_guesthouseSelectedFrequency.isEmpty) {
            errors.add('guesthouseFrequency');
          }
        } else if (_state.step1SubTypeId == 'bedding' ||
            _state.step1SubTypeId == 'appliance') {
          // 침구세탁/가전청소는 면적 입력 없음 → 검증 스킵
        } else if (_cleaningAreaController.text.trim().isEmpty) {
          errors.add('cleaningArea');
        }
        break;
      case 'expert_business':
        if (_businessLangs.isEmpty) errors.add('businessLang');
        final sub = _state.step1SubTypeId;
        if (sub == 'translate_docs' ||
            sub == 'legal_doc' ||
            sub == 'property' ||
            sub == 'customs') {
          final hasDocChip = _step2Selections
              .where((e) => _kBusinessDocChipIds.contains(e))
              .isNotEmpty;
          final hasNote = _documentTypeController.text.trim().isNotEmpty;
          if (!hasDocChip && !hasNote) {
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
        if (_tutoringLevels.isEmpty &&
            _tutorGoalController.text.trim().isEmpty) {
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
    ];
    final detailStr = detailParts.join('\n');

    final memoStr = _d3MemoController.text.trim();
    return {
      'title': titleStr.trim(),
      'location': locStr.trim(),
      'salary': scheduleStr.trim(),
      'detail': detailStr.trim(),
      if (memoStr.isNotEmpty) 'memo': memoStr,
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
          if (_state.step1SubTypeId == 'guesthouse')
            'guesthouse': <String, String>{
              'selectedArea': _guesthouseSelectedArea,
              'selectedScale': _guesthouseSelectedScale,
              'selectedFrequency': _guesthouseSelectedFrequency,
            },
          if (_state.step1SubTypeId == 'bedding') ...{
            'beddingType': _cleaningBeddingType,
            'beddingCount': _cleaningBeddingCountController.text.trim(),
          },
          if (_state.step1SubTypeId == 'appliance') ...{
            'applianceTypes': _cleaningApplianceTypes.toList(),
            'applianceCount': _cleaningApplianceCount,
          },
          if (_step2OtherSelected ||
              _step2OtherController.text.trim().isNotEmpty)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_moving':
        final isTuktukMoving = _state.step1SubTypeId == 'tuktuk';
        final isSmallOrHomeMoving = _state.step1SubTypeId == 'small' ||
            _state.step1SubTypeId == 'home';
        return {
          'fromLandmark': _d3MovingFromController.text.trim(),
          'toLandmark': _d3MovingToController.text.trim(),
          'vehicleType': isTuktukMoving ? 'tuktuk' : _movingVehicleType,
          'houseType': _movingHouseType,
          'roomCount': _movingRoomCountController.text.trim(),
          'floorFrom': _movingFloorFrom,
          'floorTo': _movingFloorTo,
          'elevator': _movingElevator,
          if (_state.step1SubTypeId == 'cargo') ...{
            'cargoTypes': _movingCargoTypes.toList(),
            'weightKg': _weightKgController.text.trim(),
            'distance': _movingDistance,
            if (_movingCargoOtherController.text.trim().isNotEmpty)
              'cargoOtherDetail': _movingCargoOtherController.text.trim(),
          },
          if (isTuktukMoving) ...{
            'cargoTypes': _movingCargoTypes.toList(),
            'distance': _movingDistance,
            if (_movingCargoOtherController.text.trim().isNotEmpty)
              'cargoOtherDetail': _movingCargoOtherController.text.trim(),
          },
          if (isSmallOrHomeMoving) ...{
            if (_movingCargoTypes.isNotEmpty)
              'cargoTypes': _movingCargoTypes.toList(),
            if (_movingCargoOtherController.text.trim().isNotEmpty)
              'cargoOtherDetail': _movingCargoOtherController.text.trim(),
          },
        };
      case 'expert_repair':
        return {
          'brand': _repairBrand,
          'symptoms': _step2Selections.toList(),
          'symptomDetail': _repairSymptomMemoController.text.trim(),
        };
      case 'expert_interior':
        return {
          'parts': _interiorParts.toList(),
          if (_step2Selections.isNotEmpty)
            'interiorSelections': _step2Selections.toList(),
          if (_interiorAreaController.text.trim().isNotEmpty)
            'areaSize': _interiorAreaController.text.trim(),
          if (_interiorBudgetController.text.trim().isNotEmpty)
            'budgetRange': _interiorBudgetController.text.trim(),
          if (_step2OtherController.text.trim().isNotEmpty)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_business':
        final subType = _state.step1SubTypeId;
        return {
          'languages': _businessLangs.toList(),
          'selections': _step2Selections.toList(),
          if (subType == 'translate_docs' ||
              subType == 'legal_doc' ||
              subType == 'property' ||
              subType == 'customs' ||
              subType == 'company_setup' ||
              subType == 'accounting')
            'documentKind': _documentTypeController.text.trim(),
          if (subType == 'interpret')
            'interpretRequest': _documentTypeController.text.trim(),
          if (subType == 'visa_permit')
            'visaRequest': _documentTypeController.text.trim(),
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
          'subject': _tutoringSubjects.toList(),
          'levels': _tutoringLevels.toList(),
          'classType': _step2Selections.toList(),
          'goal': _tutorGoalController.text.trim(),
          if (_tutorOtherController.text.trim().isNotEmpty)
            'otherNote': _tutorOtherController.text.trim()
          else if (_step2OtherSelected)
            'otherNote': _step2OtherController.text.trim(),
        };
      case 'expert_events':
        final isBaci = _state.step1SubTypeId == 'baci';
        return {
          'eventKind': isBaci ? _step2Selections.toList() : _state.step1SubTypeId,
          'expectedPeople': _eventPeopleController.text.trim(),
          if (!isBaci) 'selections': _step2Selections.toList(),
          if (_step2OtherController.text.trim().isNotEmpty)
            'eventDetail': _step2OtherController.text.trim(),
        };
      case 'expert_vehicle':
        final isTuktuk = _state.step1SubTypeId == 'tuktuk';
        final isCarRental = _state.step1SubTypeId == 'car_rental';
        final isMotoRental = _state.step1SubTypeId == 'moto_rental';
        final isCarwash = _state.step1SubTypeId == 'carwash';
        final isRepair = _state.step1SubTypeId == 'car_repair' ||
            _state.step1SubTypeId == 'moto_repair' ||
            _state.step1SubTypeId == 'tire_battery';
        return {
          if (isRepair) ...{
            'brandOrModel': _vehicleBrandController.text.trim(),
            'symptoms': _vehicleSymptoms.toList(),
            'symptomDetail': _repairSymptomMemoController.text.trim(),
          },
          if (isCarRental) ...{
            'brandOrModel': _vehicleBrandController.text.trim(),
            'carType': _step2Selections
                .where((id) => {
                      'sedan',
                      'suv',
                      'vehicle_car_van',
                      'vehicle_car_pickup',
                    }.contains(id))
                .toList(),
            'rentalDuration': _step2Selections
                .where((id) => {
                      'half_day',
                      'full_day',
                      'weekly',
                      'monthly',
                    }.contains(id))
                .toList(),
          },
          if (isMotoRental) ...{
            'brandOrModel': _vehicleBrandController.text.trim(),
            'motoType': _step2Selections
                .where((id) => {
                      'scooter',
                      'semi_auto',
                      'manual',
                      'big_bike',
                    }.contains(id))
                .toList(),
            'rentalDuration': _step2Selections
                .where((id) => {
                      'half_day',
                      'full_day',
                      'weekly',
                      'monthly',
                    }.contains(id))
                .toList(),
          },
          if (isCarwash) ...{
            'carwashType': _step2Selections
                .where((id) => {
                      'basic',
                      'interior_wash',
                      'full',
                      'coating',
                    }.contains(id))
                .toList(),
            'symptomDetail': _repairSymptomMemoController.text.trim(),
          },
          if (isTuktuk) ...{
            'tuktukType': _step2Selections
                .where((id) => {'standard', 'electric', 'cargo'}.contains(id))
                .toList(),
            'rentalDuration': _step2Selections
                .where((id) => {
                      'half_day',
                      'full_day',
                      'weekly',
                      'monthly',
                    }.contains(id))
                .toList(),
          },
          if (!isRepair &&
              !isCarRental &&
              !isMotoRental &&
              !isCarwash &&
              !isTuktuk) ...{
            'brandOrModel': _vehicleBrandController.text.trim(),
            'symptoms': _vehicleSymptoms.toList(),
            if (!isTuktuk) 'rentalOptions': _step2Selections.toList(),
            'symptomDetail': _repairSymptomMemoController.text.trim(),
          },
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

    if (key == 'guesthouse' && value is Map) {
      final m = Map<Object?, Object?>.from(value);
      String gv(String k) => '${m[k] ?? ''}'.trim();
      final area = gv('selectedArea');
      final scale = gv('selectedScale');
      final freq = gv('selectedFrequency');
      final areaStr = area.isNotEmpty ? t(area) : '';
      final scaleStr = scale.isNotEmpty ? t(scale) : '';
      final freqStr = freq.isNotEmpty ? t(freq) : '';
      return [areaStr, scaleStr, freqStr]
          .where((s) => s.isNotEmpty)
          .join(' · ');
    }

    if (key == 'vehicleType' && value == 'tuktuk') {
      return t('sub_moving_tuktuk');
    }

    if (key == 'cargoTypes' &&
        value is List &&
        _state.categoryKey == 'expert_moving' &&
        _state.step1SubTypeId == 'tuktuk') {
      String tuktukCargoLabel(String id) {
        return switch (id) {
          'moving_tuktuk_small_items' => t('moving_tuktuk_small_items'),
          'moving_tuktuk_furniture' => t('moving_tuktuk_furniture'),
          'moving_tuktuk_market_goods' => t('moving_tuktuk_market_goods'),
          'other' => t('moving_tuktuk_other'),
          _ => t(id),
        };
      }

      return value
          .map((e) => tuktukCargoLabel(e.toString()))
          .where((s) => s.isNotEmpty)
          .join(' · ');
    }

    if (key == 'cargoTypes' &&
        value is List &&
        _state.categoryKey == 'expert_moving' &&
        (_state.step1SubTypeId == 'small' ||
            _state.step1SubTypeId == 'home' ||
            _state.step1SubTypeId == 'cargo')) {
      String movingStandardCargoLabel(String id) {
        return switch (id) {
          'furniture' => t('moving_cargo_furniture'),
          'appliance' => t('moving_cargo_appliance'),
          'box' => t('moving_cargo_box'),
          'etc' => t('moving_cargo_etc'),
          'moving_cargo_motorcycle' => t('moving_cargo_motorcycle'),
          'instrument' => t('moving_cargo_instrument'),
          'buddha' => t('moving_cargo_buddha'),
          _ => id,
        };
      }

      final body = value
          .map((e) => movingStandardCargoLabel(e.toString()))
          .where((s) => s.isNotEmpty)
          .join(' · ');
      if (body.isEmpty) return '';
      return '${t('moving_cargo_type')}: $body';
    }

    if (key == 'eventKind' && value is List) {
      return value
          .map((e) {
            final id = e.toString();
            final labelKey =
                id.startsWith('baci_') ? 'events_$id' : 'sub_events_$id';
            return t(labelKey);
          })
          .where((s) => s.isNotEmpty)
          .join(' · ');
    }

    if (key == 'selections' &&
        value is List &&
        _state.categoryKey == 'expert_business') {
      String bizSelLabel(String id) {
        final trimmed = id.trim();
        return switch (trimmed) {
          'passport' => t('business_doc_passport'),
          'contract' => t('business_doc_contract'),
          'certificate' => t('business_doc_certificate'),
          'medical' => t('business_doc_medical'),
          'corporate' => t('business_doc_corporate'),
          'property' => t('business_doc_property'),
          'customs' => t('business_doc_customs'),
          _ => kStaticUiTripleByMessageKey[trimmed]?[lang] ?? trimmed,
        };
      }

      final body = value
          .map((e) => bizSelLabel(e.toString()))
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (body.isEmpty) return '';
      return '${t('wizard_step2_title')}: $body';
    }

    // 저장ID → 번역키 변환 테이블 (글로벌 i18n 표준 - 9개 카테고리 전체)
    const idToTranslationKey = <String, String>{
      // [beauty]
      'beauty_body_full': 'beauty_body_full',
      'beauty_body_back': 'beauty_body_back',
      'beauty_body_leg': 'beauty_body_leg',
      'beauty_body_head': 'beauty_body_head',
      'beauty_dur_60min': 'beauty_duration_60',
      'beauty_dur_90min': 'beauty_duration_90',
      'beauty_dur_120min': 'beauty_duration_120',
      'beauty_visit_home': 'beauty_visit_home',
      'beauty_visit_shop': 'beauty_visit_shop',
      'beauty_aroma_swedish': 'beauty_aroma_swedish',
      'beauty_aroma_deep_tissue': 'beauty_aroma_deep_tissue',
      'beauty_aroma_hot_stone': 'beauty_aroma_hot_stone',
      'beauty_aroma_foot': 'beauty_aroma_foot',
      'beauty_nail_gel': 'beauty_nail_gel',
      'beauty_nail_acrylic': 'beauty_nail_acrylic',
      'beauty_nail_art': 'beauty_nail_art',
      'beauty_nail_removal': 'beauty_nail_removal',
      'beauty_hair_cut': 'beauty_hair_cut',
      'beauty_hair_perm': 'beauty_hair_perm',
      'beauty_hair_color': 'beauty_hair_color',
      'beauty_hair_treatment': 'beauty_hair_treatment',
      'beauty_hair_styling': 'beauty_hair_styling',
      'beauty_makeup_wedding': 'beauty_makeup_wedding',
      'beauty_makeup_event': 'beauty_makeup_event',
      'beauty_makeup_daily': 'beauty_makeup_daily',
      'beauty_makeup_photo': 'beauty_makeup_photo',
      'beauty_makeup_baci': 'beauty_makeup_baci',
      'beauty_waxing_arms_legs': 'beauty_waxing_arms_legs',
      'beauty_waxing_bikini': 'beauty_waxing_bikini',
      'beauty_waxing_underarm': 'beauty_waxing_underarm',
      'beauty_waxing_face': 'beauty_waxing_face',
      'beauty_waxing_full': 'beauty_waxing_full',
      'beauty_skin_basic': 'beauty_skin_basic',
      'beauty_skin_deep': 'beauty_skin_deep',
      'beauty_skin_moisture': 'beauty_skin_moisture',
      'beauty_skin_whitening': 'beauty_skin_whitening',
      'beauty_skin_antiaging': 'beauty_skin_antiaging',
      'beauty_skin_acne': 'beauty_skin_acne',
      // [cleaning]
      'cleaning_target_home': 'cleaning_target_home',
      'cleaning_target_office': 'cleaning_target_office',
      'cleaning_target_store': 'cleaning_target_store',
      'cleaning_cycle_w1': 'cleaning_cycle_w1',
      'cleaning_cycle_w2': 'cleaning_cycle_w2',
      'cleaning_cycle_m2': 'cleaning_cycle_m2',
      'cleaning_cycle_m1': 'cleaning_cycle_m1',
      'cleaning_bedding_duvet': 'cleaning_bedding_duvet',
      'cleaning_bedding_pillow': 'cleaning_bedding_pillow',
      'cleaning_bedding_mattress': 'cleaning_bedding_mattress',
      'cleaning_bedding_set': 'cleaning_bedding_set',
      'cleaning_appliance_ac': 'cleaning_appliance_ac',
      'cleaning_appliance_fridge': 'cleaning_appliance_fridge',
      'cleaning_appliance_washer': 'cleaning_appliance_washer',
      'cleaning_appliance_dishwasher': 'cleaning_appliance_dishwasher',
      'cleaning_appliance_oven': 'cleaning_appliance_oven',
      'cleaning_appliance_microwave': 'cleaning_appliance_microwave',
      'cleaning_gh_scale_small': 'cleaning_gh_scale_small',
      'cleaning_gh_scale_medium': 'cleaning_gh_scale_medium',
      'cleaning_gh_scale_large': 'cleaning_gh_scale_large',
      'area_under10': 'area_under10',
      'area_10to20': 'area_10to20',
      'area_20to30': 'area_20to30',
      'area_over30': 'area_over30',
      'freq_daily': 'freq_daily',
      'freq_2to3week': 'freq_2to3week',
      'freq_weekly': 'freq_weekly',
      'freq_biweekly': 'freq_biweekly',
      'studio': 'cleaning_house_studio',
      // [interior]
      'interior_housing_house': 'interior_housing_house',
      'interior_housing_apartment': 'interior_housing_apartment',
      'interior_housing_condo': 'interior_housing_condo',
      'interior_housing_commercial': 'interior_housing_commercial',
      'interior_housing_villa': 'interior_housing_villa',
      'interior_housing_townhouse': 'interior_housing_townhouse',
      'interior_housing_guesthouse': 'interior_housing_guesthouse',
      'interior_wallpaper_paper': 'interior_wallpaper_paper',
      'interior_wallpaper_fabric': 'interior_wallpaper_fabric',
      'interior_wallpaper_paint': 'interior_wallpaper_paint',
      'interior_floor_tile': 'interior_floor_tile',
      'interior_floor_wood': 'interior_floor_wood',
      'interior_floor_marble': 'interior_floor_marble',
      'interior_floor_vinyl': 'interior_floor_vinyl',
      'interior_budget_s': 'interior_budget_s',
      'interior_budget_m': 'interior_budget_m',
      'interior_budget_l': 'interior_budget_l',
      'interior_painting_interior': 'interior_painting_interior',
      'interior_painting_exterior': 'interior_painting_exterior',
      'interior_scope_both': 'interior_scope_both',
      'interior_bathroom_tile': 'interior_bathroom_tile',
      'interior_bathroom_toilet': 'interior_bathroom_toilet',
      'interior_bathroom_sink': 'interior_bathroom_sink',
      'interior_bathroom_shower': 'interior_bathroom_shower',
      'interior_bathroom_full': 'interior_bathroom_full',
      'interior_kitchen_cabinet': 'interior_kitchen_cabinet',
      'interior_kitchen_countertop': 'interior_kitchen_countertop',
      'interior_kitchen_sink': 'interior_kitchen_sink',
      'interior_kitchen_full': 'interior_kitchen_full',
      'interior_remodel_partial': 'interior_remodel_partial',
      'interior_remodel_full': 'interior_remodel_full',
      // [moving]
      'pickup': 'moving_vehicle_pickup',
      'van': 'moving_vehicle_van',
      'small_truck': 'moving_vehicle_small_truck',
      'motorcycle': 'moving_vehicle_motorcycle',
      'furniture': 'moving_cargo_furniture',
      'appliance': 'moving_cargo_appliance',
      'box': 'moving_cargo_box',
      'instrument': 'moving_cargo_instrument',
      'buddha': 'moving_cargo_buddha',
      'moving_cargo_etc': 'moving_cargo_etc',
      'yes': 'moving_elevator_yes',
      'no': 'moving_elevator_no',
      'moving_house_apartment': 'moving_house_apartment',
      'moving_house_villa': 'moving_house_villa',
      'moving_house_detached': 'moving_house_detached',
      'moving_house_studio': 'moving_house_studio',
      'moving_house_townhouse': 'moving_house_townhouse',
      'moving_cargo_motorcycle': 'moving_cargo_motorcycle',
      'moving_distance_local': 'moving_distance_local',
      'moving_distance_city': 'moving_distance_city',
      'moving_distance_intercity': 'moving_distance_intercity',
      'moving_tuktuk_small_items': 'moving_tuktuk_small_items',
      'moving_tuktuk_furniture': 'moving_tuktuk_furniture',
      'moving_tuktuk_market_goods': 'moving_tuktuk_market_goods',
      // [tutoring]
      'online': 'tutor_class_online',
      'visit': 'tutor_class_visit',
      'center': 'tutor_class_center',
      'elem': 'wizard_level_elem',
      'mid': 'wizard_level_mid',
      'high': 'wizard_level_high',
      'adult': 'wizard_level_adult',
      'beginner': 'tutor_exp_beginner',
      'intermediate': 'tutor_exp_intermediate',
      'advanced': 'tutor_exp_advanced',
      // [vehicle]
      'engine': 'wizard_vehicle_sym_engine',
      'tire': 'wizard_vehicle_sym_tire',
      'accident': 'wizard_vehicle_sym_accident',
      'electrical': 'wizard_vehicle_sym_electrical',
      'brake': 'vehicle_sym_brake',
      'chain': 'vehicle_sym_chain',
      'vehicle_sym_ac': 'vehicle_sym_ac',
      'sedan': 'vehicle_car_sedan',
      'suv': 'vehicle_car_suv',
      'vehicle_car_van': 'vehicle_car_van',
      'vehicle_car_pickup': 'vehicle_car_pickup',
      'half_day': 'vehicle_rental_half_day',
      'full_day': 'vehicle_rental_full_day',
      'weekly': 'vehicle_rental_weekly',
      'monthly': 'vehicle_rental_monthly',
      'scooter': 'vehicle_moto_scooter',
      'semi_auto': 'vehicle_moto_semi_auto',
      'manual': 'vehicle_moto_manual',
      'big_bike': 'vehicle_moto_big_bike',
      'basic': 'vehicle_carwash_basic',
      'interior_wash': 'vehicle_carwash_interior',
      'full': 'vehicle_carwash_full',
      'coating': 'vehicle_carwash_coating',
      'standard': 'vehicle_tuktuk_standard',
      'electric': 'vehicle_tuktuk_electric',
      'cargo': 'vehicle_tuktuk_cargo',
      'flat': 'wizard_vehicle_sym_tire',
      'battery': 'wizard_vehicle_sym_electrical',
      // [events]
      'natural': 'events_photo_natural',
      'events_photo_studio': 'events_photo_studio',
      'outdoor': 'events_photo_outdoor',
      'indoor': 'events_photo_indoor',
      'photo_only': 'events_deliverable_photo',
      'video_only': 'events_deliverable_video',
      'both': 'events_deliverable_both',
      'scale_s': 'events_scale_s',
      'scale_m': 'events_scale_m',
      'scale_l': 'events_scale_l',
      'baci_wedding': 'events_baci_wedding',
      'baci_newborn': 'events_baci_newborn',
      'baci_housewarming': 'events_baci_housewarming',
      'baci_farewell': 'events_baci_farewell',
      'baci_other': 'events_baci_other',
      // [repair - electric]
      'repair_elec_outlet': 'symptom_elec_outlet',
      'repair_elec_lighting': 'symptom_elec_lighting',
      'repair_elec_breaker': 'symptom_elec_breaker',
      'repair_elec_aircon': 'symptom_elec_aircon',
      'repair_elec_intercom': 'symptom_elec_intercom',
      'repair_elec_other': 'symptom_other',
      // [repair - plumbing]
      'repair_plumb_leak': 'symptom_plumb_leak',
      'repair_plumb_toilet': 'symptom_plumb_toilet',
      'repair_plumb_sink': 'symptom_plumb_sink',
      'repair_plumb_water_heater': 'symptom_plumb_water_heater',
      'repair_plumb_drain': 'symptom_plumb_drain',
      'repair_plumb_other': 'symptom_other',
      // [repair - roof/paint]
      'repair_roof_interior': 'symptom_roof_interior',
      'repair_roof_exterior': 'symptom_roof_exterior',
      'repair_roof_leak': 'symptom_roof_leak',
      'repair_roof_replace': 'symptom_roof_replace',
      'repair_roof_waterproof': 'symptom_roof_waterproof',
      'repair_roof_other': 'symptom_other',
      // [repair - appliance symptoms]
      'symptom_ac_no_cold_air': 'symptom_ac_no_cold_air',
      'symptom_ac_noise': 'symptom_ac_noise',
      'symptom_ac_water_sound': 'symptom_ac_water_sound',
      'symptom_ac_not_cool': 'symptom_ac_not_cool',
      'symptom_fridge_no_cool': 'symptom_fridge_no_cool',
      'symptom_fridge_noise': 'symptom_fridge_noise',
      'symptom_fridge_door': 'symptom_fridge_door',
      'symptom_fridge_ice': 'symptom_fridge_ice',
      'symptom_washer_no_spin': 'symptom_washer_no_spin',
      'symptom_washer_water_leak': 'symptom_washer_water_leak',
      'symptom_washer_noise': 'symptom_washer_noise',
      'symptom_washer_no_power': 'symptom_washer_no_power',
      'symptom_tv_no_display': 'symptom_tv_no_display',
      'symptom_tv_no_sound': 'symptom_tv_no_sound',
      'symptom_tv_no_power': 'symptom_tv_no_power',
      'symptom_tv_remote': 'symptom_tv_remote',
      'symptom_wp_water_leak': 'symptom_wp_water_leak',
      'symptom_wp_no_cold': 'symptom_wp_no_cold',
      'symptom_wp_no_hot': 'symptom_wp_no_hot',
      'symptom_wp_filter': 'symptom_wp_filter',
      'symptom_fan_no_spin': 'symptom_fan_no_spin',
      'symptom_fan_noise': 'symptom_fan_noise',
      'symptom_fan_no_power': 'symptom_fan_no_power',
      'symptom_rc_no_cook': 'symptom_rc_no_cook',
      'symptom_rc_no_heat': 'symptom_rc_no_heat',
      'symptom_rc_no_power': 'symptom_rc_no_power',
      'symptom_gen_no_start': 'symptom_gen_no_start',
      'symptom_gen_no_power': 'symptom_gen_no_power',
      'symptom_gen_noise': 'symptom_gen_noise',
      'symptom_gen_fuel_leak': 'symptom_gen_fuel_leak',
      'symptom_wp_no_water': 'symptom_wp_no_water',
      'symptom_wp_low_pressure': 'symptom_wp_low_pressure',
      'symptom_wp_noise': 'symptom_wp_noise',
      'symptom_wp_no_start': 'symptom_wp_no_start',
      'symptom_sp_no_charge': 'symptom_sp_no_charge',
      'symptom_sp_low_output': 'symptom_sp_low_output',
      'symptom_sp_panel_damage': 'symptom_sp_panel_damage',
      'symptom_other': 'symptom_other',
      'symptom_other_broken': 'symptom_other_broken',
      'symptom_other_noise': 'symptom_other_noise',
      'symptom_other_no_power': 'symptom_other_no_power',
      // [business]
      'lang_zh': 'wizard_lang_zh',
      'lang_th': 'wizard_lang_th',
    };

    if (key == 'tuktukType' && value is List) {
      return value
          .map((e) {
            final id = e.toString();
            final translationKey = idToTranslationKey[id] ?? id;
            return kStaticUiTripleByMessageKey[translationKey]?[lang] ?? id;
          })
          .where((s) => s.isNotEmpty)
          .join(' · ');
    }

    if (value == null) return '';
    final rawValue = value is List
        ? value.map((e) {
            final s = '$e'.trim();
            final translationKey = idToTranslationKey[s] ?? s;
            return kStaticUiTripleByMessageKey[translationKey]?[lang] ??
                kStaticUiTripleByMessageKey[s]?[lang] ??
                s;
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
        if (_state.categoryKey == 'expert_moving') {
          final label = kStaticUiTripleByMessageKey[rawValue]?[lang]
              ?? kStaticUiTripleByMessageKey['moving_house_$rawValue']?[lang]
              ?? rawValue;
          return '${t('moving_house_type')}: $label';
        }
        return '${t('cleaning_house_type')}: ${t('cleaning_house_$rawValue')}';
      case 'roomCount':
        return '${t('cleaning_room_count')}: $rawValue';
      case 'bathroomCount':
        return '${t('cleaning_bathroom_count')}: $rawValue';
      case 'otherNote':
        final otherLabelKey = switch (_state.categoryKey) {
          'expert_repair' => 'repair_other_label',
          'expert_moving' => 'moving_cargo_other_label',
          'expert_interior' => 'interior_other_label',
          'expert_business' => switch (_state.step1SubTypeId) {
            'interpret' => 'business_interpret_other_label',
            'visa' => 'business_visa_other_label',
            _ => 'business_doc_other_label',
          },
          'expert_beauty' => 'beauty_other_label',
          'expert_tutoring' => 'tutor_other_label',
          'expert_cleaning' => 'cleaning_other_label',
          _ => 'wizard_other_service_label',
        };
        return '${t(otherLabelKey)}: $rawValue';
      case 'customService':
        return '${t('wizard_other_service_label')}: $rawValue';

      // ── 청소 ──────────────────────────────────
      case 'industry':
        return '${t('wizard_cleaning_restaurant_label')}: $rawValue';
      case 'target':
        final targetLabel = kStaticUiTripleByMessageKey[rawValue]?[lang] ?? rawValue;
        return '${t('cleaning_visit_target')}: $targetLabel';
      case 'visitCycle':
        final cycleLabel = kStaticUiTripleByMessageKey[rawValue]?[lang] ?? rawValue;
        return '${t('cleaning_visit_cycle')}: $cycleLabel';
      case 'beddingType':
        final beddingLabel =
            kStaticUiTripleByMessageKey[rawValue]?[lang] ?? rawValue;
        return '${t('cleaning_bedding_type')}: $beddingLabel';
      case 'beddingCount':
        return '${t('cleaning_appliance_count')}: $rawValue';
      case 'applianceTypes':
        return '${t('cleaning_appliance_type')}: $rawValue';
      case 'applianceCount':
        return '${t('cleaning_appliance_count')}: $rawValue';

      // ── 이사 ──────────────────────────────────
      case 'vehicleType':
        final vehicleLabel = kStaticUiTripleByMessageKey[
              idToTranslationKey[rawValue] ?? rawValue
            ]?[lang] ?? rawValue;
        return '${t('moving_vehicle_type')}: $vehicleLabel';
      case 'floorFrom':
        final floorFromLabel = kStaticUiTripleByMessageKey[
              'moving_floor_${rawValue.replaceAll('+', 'plus')}'
            ]?[lang] ?? rawValue;
        return '${t('moving_floor_from')}: $floorFromLabel';
      case 'floorTo':
        final floorToLabel = kStaticUiTripleByMessageKey[
              'moving_floor_${rawValue.replaceAll('+', 'plus')}'
            ]?[lang] ?? rawValue;
        return '${t('moving_floor_to')}: $floorToLabel';
      case 'elevator':
        final elevatorLabel = kStaticUiTripleByMessageKey[
              idToTranslationKey[rawValue] ?? rawValue
            ]?[lang] ?? rawValue;
        return '${t('moving_elevator')}: $elevatorLabel';
      case 'cargoTypes':
        if (value is List) {
          final labels = value.map((e) {
            final id = e.toString();
            final key = idToTranslationKey[id] ?? id;
            return kStaticUiTripleByMessageKey[key]?[lang] ?? id;
          }).where((s) => s.isNotEmpty).join(', ');
          return '${t('moving_cargo_type')}: $labels';
        }
        return '${t('moving_cargo_type')}: $rawValue';
      case 'cargoOtherDetail':
        return '${t('moving_cargo_other_label')}: $rawValue';
      case 'weightKg':
        return '${t('moving_weight')}: $rawValue kg';
      case 'distance':
        final distanceLabel = kStaticUiTripleByMessageKey[
              idToTranslationKey[rawValue] ?? rawValue
            ]?[lang] ?? rawValue;
        return '${t('moving_distance')}: $distanceLabel';
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
            ? (_state.step1SubTypeId == 'carwash'
                ? 'vehicle_carwash_memo_label'
                : 'vehicle_symptom_memo_label')
            : 'wizard_repair_symptom_memo_label';
        return '${t(memoLabel)}: $rawValue';

      // ── 인테리어 ───────────────────────────────
      case 'parts':
        if (value is List) {
          final labels = value.map((e) {
            final id = e.toString();
            final key = idToTranslationKey[id] ?? id;
            return kStaticUiTripleByMessageKey[key]?[lang] ?? id;
          }).where((s) => s.isNotEmpty).join(', ');
          return '${t('interior_housing_type')}: $labels';
        }
        return '${t('interior_housing_type')}: $rawValue';
      case 'budgetRange':
        final budgetKey = idToTranslationKey[rawValue] ?? rawValue;
        final budgetLabel = kStaticUiTripleByMessageKey[budgetKey]?[lang] ?? rawValue;
        return '${t('interior_budget_label')}: $budgetLabel';
      case 'areaSize':
        return '${t('interior_area_label')}: $rawValue sqm';
      case 'interiorSelections':
        if (value is List) {
          final labels = value.map((e) {
            final id = e.toString();
            final key = idToTranslationKey[id] ?? id;
            return kStaticUiTripleByMessageKey[key]?[lang] ?? id;
          }).where((s) => s.isNotEmpty).join(', ');
          if (labels.isEmpty) return '';
          return '${t('wizard_step2_title')}: $labels';
        }
        return '';

      // ── 비즈니스·번역 ──────────────────────────
      case 'languages':
        return '${t('wizard_business_lang_title')}: $rawValue';
      case 'documentKind':
        return '${t('wizard_business_doc_type_label')}: $rawValue';
      case 'interpretRequest':
        return '${t('business_interpret_other_label')}: $rawValue';
      case 'visaRequest':
        return '${t('business_visa_other_label')}: $rawValue';
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
        if (value == null) return '';
        final subjects = value is List ? value : [value];
        if (subjects.isEmpty) return '';
        final labels = subjects
            .map((e) {
              final s = '$e'.trim();
              final subjectKey = 'sub_tutor_$s';
              return kStaticUiTripleByMessageKey[subjectKey]?[lang]
                  ?? kStaticUiTripleByMessageKey[s]?[lang]
                  ?? '';
            })
            .where((s) => s.isNotEmpty)
            .join(', ');
        return labels.isNotEmpty
            ? '${t('wizard_tutoring_subject_from_step1')}: $labels'
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
        final symptomTitleKey = _state.categoryKey == 'expert_vehicle'
            ? 'wizard_vehicle_symptom_title'
            : 'wizard_repair_symptom_title';
        return '${t(symptomTitleKey)}: $rawValue';
      case 'carType':
        if (rawValue.isEmpty) return '';
        return '${t('vehicle_car_type_title')}: $rawValue';
      case 'motoType':
        if (rawValue.isEmpty) return '';
        return '${t('vehicle_moto_type_title')}: $rawValue';
      case 'rentalDuration':
        if (rawValue.isEmpty) return '';
        return '${t('vehicle_rental_duration_title')}: $rawValue';
      case 'carwashType':
        if (rawValue.isEmpty) return '';
        return '${t('vehicle_carwash_type_title')}: $rawValue';
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
    debugPrint('[SUBMIT] Start');

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
          debugPrint('[SUBMIT] No Firebase, skipping save');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n('wizard_need_firebase_for_photos'))),
            );
          }
          photoUrls = <String>[];
        } else {
          // ignore: avoid_print
          debugPrint('[SUBMIT] Checking online status');
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
          debugPrint('[SUBMIT] Network status checked (online=$online)');
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
              debugPrint('[SUBMIT] Photo upload started');
              photoUrls = await uploadExpertRequestImagesFromXFiles(
                files: _pickedImages,
                userId: uid,
              ).timeout(const Duration(seconds: 30));
              // ignore: avoid_print
              debugPrint('[SUBMIT] Photo upload done: ${photoUrls.length} URLs');
            } on TimeoutException catch (e) {
              if (kDebugMode) debugPrint('UniversalWizard: ?ъ쭊 ?낅줈????꾩븘?? $e');
              // ignore: avoid_print
              debugPrint('[SUBMIT] Photo upload skipped, proceeding with photoUrls=[]');
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
              debugPrint('[SUBMIT] Photo upload failed, proceeding with photoUrls=[]: $e');
              photoUrls = <String>[];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n('wizard_upload_failed'))),
                );
              }
            } finally {
              // ignore: avoid_print
              debugPrint('[SUBMIT] Photo upload finally (continuing regardless)');
              if (mounted) Navigator.of(context).pop();
            }
          } else {
            photoLocalPaths =
                _pickedImages.map((e) => e.path).where((s) => s.isNotEmpty).toList();
            // ignore: avoid_print
            debugPrint('[SUBMIT] No Firebase, skipping ${_pickedImages.length} photos');
          }
        }
      } else {
        // ignore: avoid_print
        debugPrint('[SUBMIT] No Firebase, skipping save');
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
      debugPrint('[SUBMIT] Save started');
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
      debugPrint('[SUBMIT] Save complete');

      final body = <String, dynamic>{
        'category': _categoryEnglish(_state.categoryKey),
        'categoryKey': _state.categoryKey,
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
        'memoI18n': wizardI18n['memo'] is Map
            ? wizardI18n['memo'] as Map<String, dynamic>
            : null,
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
      debugPrint('[SUBMIT] Firestore save started (photos=${photoUrls.length})');
      unawaited(
        saveExpertRequestV5OfflineFirst(body).then((_) {
          debugPrint('[SUBMIT] Firestore save complete (Background)');
          _pendingSaveCompleter?.complete();
        }).catchError((e) {
          debugPrint('[SUBMIT ERROR] Firestore background save failed: $e');
          _pendingSaveCompleter?.complete();
        }),
      );
      if (submitProgressShown && mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      debugPrint('[SUBMIT] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n('wizard_submit_error'))),
      );
      return;
    } finally {
      debugPrint('[SUBMIT] Finally executed');
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    debugPrint('[RADAR] _showSuccessDialog 호출');
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    debugPrint('[RADAR] _showSuccessDialog 호출');
    if (!mounted) return;
    final now = DateTime.now();
    final receiptNo =
        'LT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(1000 + (now.millisecondsSinceEpoch % 9000)).toString()}';
    debugPrint('[RADAR] 신청완료 페이지로 이동: $receiptNo');
    final saveCompleter = Completer<void>();
    _pendingSaveCompleter = saveCompleter;
    context.go('/request_complete', extra: {
      'receiptNo': receiptNo,
      'saveCompleter': saveCompleter,
    });
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
    if (!mounted) return;
    final initialTime = _state.preferredTimeStr.isNotEmpty
        ? _state.preferredTimeStr
        : '09:00';
    final result = await showTimePickerDrum(context, initialTime: initialTime);
    if (result == null || !mounted) return;
    setState(() {
      _state = _state.copyWith(preferredTimeStr: result);
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
      tutoringSubjects: _tutoringSubjects,
      onSubTypeSelected: (id, label) {
        setState(() {
          if (_config?.categoryKey == 'expert_tutoring') {
            _resetAllInputs();
            if (_tutoringSubjects.contains(id)) {
              _tutoringSubjects.remove(id);
            } else {
              _tutoringSubjects.add(id);
            }
            return;
          }
          if (_state.step1SubTypeId != id) {
            _resetAllInputs();
          }
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
      final hintKey = switch (_state.categoryKey) {
        'expert_cleaning' => 'wizard_other_hint_cleaning',
        'expert_moving' => 'wizard_other_hint_moving',
        'expert_repair' => 'wizard_other_hint_repair',
        'expert_interior' => 'wizard_other_hint_interior',
        'expert_beauty' => 'wizard_other_hint_beauty',
        'expert_tutoring' => 'wizard_other_hint_tutoring',
        'expert_events' => 'wizard_other_hint_events',
        'expert_business' => 'wizard_other_hint_business',
        'expert_vehicle' => 'wizard_other_hint_vehicle',
        _ => 'wizard_other_service_name_hint',
      };
      final lang = _currentLangCode();
      final hint = kStaticUiTripleByMessageKey[hintKey]?[lang] ??
          kStaticUiTripleByMessageKey['wizard_other_service_name_hint']?[lang] ??
          '';
      return [
        TextField(
          controller: _step1OtherServiceController,
          onChanged: (_) => setState(() {
            if (_step1OtherServiceController.text.trim().isNotEmpty) {
              _fieldErrors.remove('otherService');
            }
          }),
          decoration: wizardOutlineFieldDecoration(
            context.l10n('wizard_other_service_name_label'),
            hint: hint,
            isRequired: true,
            hasError: _fieldErrors.contains('otherService'),
            errorText: context.l10n('wizard_field_required'),
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
        if (sub == 'appliance') {
          return _buildStep2RepairV5();
        }
        if (sub == 'electric') {
          return [
              WizardStep2Electric(
                step2Selections: _step2Selections,
                otherController: _repairSymptomMemoController,
                currentLangCode: _currentLangCode(),
                onSelectionToggled: (id, selected) => setState(() {
                  selected
                      ? _step2Selections.remove(id)
                      : _step2Selections.add(id);
                }),
                onStateChanged: () => setState(() {}),
              ),
            ];
        }
        if (sub == 'plumbing') {
          return [
              WizardStep2Plumbing(
                step2Selections: _step2Selections,
                otherController: _repairSymptomMemoController,
                currentLangCode: _currentLangCode(),
                onSelectionToggled: (id, selected) => setState(() {
                  selected
                      ? _step2Selections.remove(id)
                      : _step2Selections.add(id);
                }),
                onStateChanged: () => setState(() {}),
              ),
            ];
        }
        if (sub == 'roof') {
          return [
              WizardStep2RoofPaint(
                step2Selections: _step2Selections,
                otherController: _repairSymptomMemoController,
                currentLangCode: _currentLangCode(),
                onSelectionToggled: (id, selected) => setState(() {
                  selected
                      ? _step2Selections.remove(id)
                      : _step2Selections.add(id);
                }),
                onStateChanged: () => setState(() {}),
              ),
            ];
        }
        return _buildStep2GenericMultiSelect();
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
        otherController: _step2OtherController,
        step2Selections: _step2Selections,
        currentLangCode: _currentLangCode(),
        onScaleChanged: (v) => setState(() => _cleaningScale = v),
        onHouseTypeChanged: (v) => setState(() => _cleaningHouseType = v),
        onRoomCountChanged: (v) => setState(() => _cleaningRoomCount = v),
        onBathroomCountChanged: (v) =>
            setState(() => _cleaningBathroomCount = v),
        onVisitCycleChanged: (v) => setState(() => _cleaningVisitCycle = v),
        guesthouseSelectedArea: _guesthouseSelectedArea,
        guesthouseSelectedScale: _guesthouseSelectedScale,
        guesthouseSelectedFrequency: _guesthouseSelectedFrequency,
        onGuesthouseAreaChanged: (v) => setState(() {
          _guesthouseSelectedArea = v;
          if (v.isNotEmpty) _fieldErrors.remove('guesthouseArea');
        }),
        onGuesthouseScaleChanged: (v) => setState(() {
          _guesthouseSelectedScale = v;
          if (v.isNotEmpty) _fieldErrors.remove('guesthouseScale');
        }),
        onGuesthouseFrequencyChanged: (v) => setState(() {
          _guesthouseSelectedFrequency = v;
          if (v.isNotEmpty) _fieldErrors.remove('guesthouseFrequency');
        }),
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
        otherController: _movingCargoOtherController,
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
      onStateChanged: () => setState(() {}),
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
        areaController: _interiorAreaController,
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
          if (_step2Selections.any(_kBusinessDocChipIds.contains)) {
            _fieldErrors.remove('documentType');
          }
        }),
        onStateChanged: () => setState(() {
          if (_documentTypeController.text.trim().isNotEmpty) {
            _fieldErrors.remove('documentType');
          }
          if (_step2Selections.any(_kBusinessDocChipIds.contains)) {
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
        subTypeId: _tutoringSubjects.isNotEmpty
            ? _tutoringSubjects.first
            : _state.step1SubTypeId,
        tutoringSubjects: _tutoringSubjects,
        tutoringLevels: _tutoringLevels,
        step2Selections: _step2Selections,
        goalController: _tutorGoalController,
        otherController: _tutorOtherController,
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
                      _submit();
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

