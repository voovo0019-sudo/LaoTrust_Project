// Step 3: 사진·추가 요청 (70% 동선). 갤러리/카메라 연동 추후. / Photo upload & extra note.

import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import '../request_flow_state.dart';

class Step3PhotoDetailStep extends StatelessWidget {
  const Step3PhotoDetailStep({
    super.key,
    required this.state,
    required this.onChanged,
  });
  final RequestFlowState state;
  final ValueChanged<RequestFlowState> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('request_step3_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('request_step3_desc'),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => onChanged(state.copyWith(photoPath: 'placeholder_path')),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: state.photoPath != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: colorScheme.primary, size: 48),
                          const SizedBox(height: 8),
                          Text(context.t('request_photo_attached'), style: TextStyle(color: colorScheme.onSurface)),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(context.t('request_photo_add_tap'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.extraNote,
            decoration: InputDecoration(
              labelText: context.t('wizard_extra_request_label'),
              hintText: context.t('wizard_extra_request_hint'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            onChanged: (v) => onChanged(state.copyWith(extraNote: v)),
          ),
        ],
      ),
    );
  }
}
