import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/translation_mapper.dart';
import '../../core/providers/radar_provider.dart';

class RequestCompleteScreen extends ConsumerStatefulWidget {
  const RequestCompleteScreen({
    super.key,
    required this.receiptNo,
    this.saveCompleter,
  });

  static const String routeName = '/request-complete';
  final String receiptNo;
  final Completer<void>? saveCompleter;

  @override
  ConsumerState<RequestCompleteScreen> createState() =>
      _RequestCompleteScreenState();
}

class _RequestCompleteScreenState
    extends ConsumerState<RequestCompleteScreen> {
  bool _isSaveComplete = false;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startProgress();
    _waitForSave();
  }

  void _startProgress() {
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_isSaveComplete) {
            _progress = 1.0;
            timer.cancel();
          } else {
            if (_progress < 0.85) {
              _progress += 0.02;
            }
          }
        });
      },
    );
  }

  Future<void> _waitForSave() async {
    if (widget.saveCompleter == null) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isSaveComplete = true);
      return;
    }
    try {
      await widget.saveCompleter!.future
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    if (mounted) setState(() => _isSaveComplete = true);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode
            .toLowerCase()
            .startsWith('ko')
        ? 'ko'
        : Localizations.localeOf(context)
                .languageCode
                .toLowerCase()
                .startsWith('lo')
            ? 'lo'
            : 'en';
    String t(String key) =>
        kStaticUiTripleByMessageKey[key]?[lang] ?? key;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF3B5BDB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF3B5BDB),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                t('request_success_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                t('request_success_message'),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B5BDB).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      t('request_success_receipt'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.receiptNo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B5BDB),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t('request_success_contact_time'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isSaveComplete
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSaveComplete
                              ? Icons.check_circle
                              : Icons.cloud_upload_outlined,
                          size: 16,
                          color: _isSaveComplete
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF3B5BDB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isSaveComplete
                              ? t('save_complete_message')
                              : t('saving_message'),
                          style: TextStyle(
                            fontSize: 13,
                            color: _isSaveComplete
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF3B5BDB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isSaveComplete
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF3B5BDB),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaveComplete
                      ? () => context.go('/my_requests')
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B5BDB),
                    side: BorderSide(
                      color: _isSaveComplete
                          ? const Color(0xFF3B5BDB)
                          : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    t('request_success_view_history'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    context.go('/main');
                    await Future.delayed(
                        const Duration(milliseconds: 300));
                    ref.read(radarProvider.notifier).trigger();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5BDB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    t('request_success_home'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
