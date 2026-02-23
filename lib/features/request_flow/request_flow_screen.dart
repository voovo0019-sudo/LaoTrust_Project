// =============================================================================
// LT-09 Feature: request_flow (70% 숨고식 견적 요청 동선)
// 질문지 → 제출 → 오프라인 우선 저장. 30% Jobs 동선과 충돌 없이 별도 플로우.
// Handover: 한/영 주석 · 인계용.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/offline_first_sync.dart';
import 'request_flow_state.dart';
import 'steps/step1_symptom_step.dart';
import 'steps/step2_location_time_step.dart';
import 'steps/step3_photo_detail_step.dart';

/// 70% 전문가 매칭 플로우 (LT-04, LT-06). 진행 표시줄, 슬라이드 전환, 상태 보존.
class RequestFlowScreen extends StatefulWidget {
  const RequestFlowScreen({super.key});
  static const String routeName = '/request-flow';

  @override
  State<RequestFlowScreen> createState() => _RequestFlowScreenState();
}

class _RequestFlowScreenState extends State<RequestFlowScreen> {
  static const int totalSteps = 3;
  late PageController _pageController;
  late RequestFlowState _state;
  String _category = '';
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _state = RequestFlowState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RequestFlowArgs) {
      _category = args.category;
      _state = _state.copyWith(category: _category);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStepIndex < totalSteps - 1) {
      setState(() => _currentStepIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _submit() async {
    await _state.persist();
    await saveRequestOfflineFirst(
      category: _state.category,
      payload: {
        'symptoms': _state.selectedSymptomIds,
        'location': _state.location,
        'wishedTime': _state.wishedTime,
        'extraNote': _state.extraNote,
      },
    );
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n('request_complete_title')),
        content: Text(ctx.l10n('request_complete_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(ctx.l10n('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(_category),
      ),
      body: Column(
        children: [
          _ProgressBar(
            current: _currentStepIndex + 1,
            total: totalSteps,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1SymptomStep(
                  state: _state,
                  onChanged: (s) => setState(() => _state = s),
                ),
                Step2LocationTimeStep(
                  state: _state,
                  onChanged: (s) => setState(() => _state = s),
                ),
                Step3PhotoDetailStep(
                  state: _state,
                  onChanged: (s) => setState(() => _state = s),
                ),
              ],
            ),
          ),
          _BottomButton(
            step: _currentStepIndex,
            totalSteps: totalSteps,
            onPressed: _goNext,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.current,
    required this.total,
    required this.colorScheme,
  });
  final int current;
  final int total;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surface,
      child: Row(
        children: [
          Text(
            'Step $current / $total',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.step,
    required this.totalSteps,
    required this.onPressed,
    required this.colorScheme,
  });
  final int step;
  final int totalSteps;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.inverseSurface,
              foregroundColor: colorScheme.onInverseSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isLast ? context.l10n('submit') : context.l10n('next_step')),
          ),
        ),
      ),
    );
  }
}

/// 홈 → 질문지 진입 시 카테고리 전달. / Category passed from Home to Request Flow.
class RequestFlowArgs {
  const RequestFlowArgs({required this.category});
  final String category;
}
