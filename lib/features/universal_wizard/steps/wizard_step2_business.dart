// =============================================================================
// wizard_step2_business.dart
// Step2: 비즈니스·번역 카테고리 상세 선택 UI
// =============================================================================
import 'package:flutter/material.dart';
import '../../../core/translation_mapper.dart';
import 'wizard_common.dart';

class WizardStep2Business extends StatelessWidget {
  final String subTypeId;
  final Set<String> businessLangs;
  final Set<String> step2Selections;
  final TextEditingController documentTypeController;
  final String currentLangCode;
  final String Function(String key) l10n;
  final void Function(String, bool) onLangToggled;
  final void Function(String, bool) onSelectionToggled;
  final VoidCallback onStateChanged;

  const WizardStep2Business({
    super.key,
    required this.subTypeId,
    required this.businessLangs,
    required this.step2Selections,
    required this.documentTypeController,
    required this.currentLangCode,
    required this.l10n,
    required this.onLangToggled,
    required this.onSelectionToggled,
    required this.onStateChanged,
  });

  String _t(String key) =>
      kStaticUiTripleByMessageKey[key]?[currentLangCode] ?? key;

  static const _langOptions = [
    ('lang_ko', 'lang_ko'),
    ('lang_lo', 'lang_lo'),
    ('lang_en', 'lang_en'),
    ('lang_zh', 'wizard_lang_zh'),
    ('lang_th', 'wizard_lang_th'),
  ];

  static const _interpretFields = [
    'wizard_interpret_field_business',
    'wizard_interpret_field_medical',
    'wizard_interpret_field_legal',
    'wizard_interpret_field_event',
    'wizard_interpret_field_daily',
  ];

  static const _visaTypes = [
    'wizard_visa_type_business',
    'wizard_visa_type_work',
    'wizard_visa_type_tourist',
    'wizard_visa_type_extend',
    'wizard_visa_type_ngo',
  ];

  Widget _langSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('wizard_business_lang_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 10),
          for (final k in _langOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: wizardOutlineToggleTile(
                label: l10n(k.$2),
                selected: businessLangs.contains(k.$1),
                onTap: () =>
                    onLangToggled(k.$1, businessLangs.contains(k.$1)),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (subTypeId == 'translate_docs' || subTypeId == 'legal_doc') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _langSection(),
          const SizedBox(height: 16),
          TextField(
            controller: documentTypeController,
            onChanged: (_) => onStateChanged(),
            decoration: wizardOutlineFieldDecoration(
              _t('wizard_business_doc_type_label'),
              hint: _t('wizard_business_doc_type_hint'),
            ),
          ),
        ],
      );
    }

    if (subTypeId == 'interpret') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _langSection(),
          const SizedBox(height: 16),
          Text(
            _t('wizard_interpret_field_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 10),
          for (final f in _interpretFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: wizardOutlineToggleTile(
                label: _t(f),
                selected: step2Selections.contains(f),
                onTap: () =>
                    onSelectionToggled(f, step2Selections.contains(f)),
              ),
            ),
        ],
      );
    }

    if (subTypeId == 'visa_permit') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _langSection(),
          const SizedBox(height: 16),
          Text(
            _t('wizard_visa_type_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 10),
          for (final v in _visaTypes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: wizardOutlineToggleTile(
                label: _t(v),
                selected: step2Selections.contains(v),
                onTap: () =>
                    onSelectionToggled(v, step2Selections.contains(v)),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _langSection(),
        const SizedBox(height: 16),
        TextField(
          controller: documentTypeController,
          onChanged: (_) => onStateChanged(),
          decoration: wizardOutlineFieldDecoration(
            _t('wizard_business_detail_label'),
            hint: _t('wizard_business_detail_hint'),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
