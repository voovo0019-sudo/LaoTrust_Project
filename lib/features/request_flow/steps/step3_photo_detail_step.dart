// Step 3: 사진·추가 요청 (70% 동선). 갤러리/카메라 연동 추후. / Photo upload & extra note.

import 'package:flutter/material.dart';
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
          const Text(
            '사진 및 추가 요청',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '현장 사진을 올리면 전문가가 더 정확한 견적을 드립니다.',
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
                          Text('사진이 첨부되었습니다', style: TextStyle(color: colorScheme.onSurface)),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('사진 추가 (탭)', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.extraNote,
            decoration: const InputDecoration(
              labelText: '추가 요청사항',
              hintText: '전문가에게 전달할 메모를 입력하세요',
              border: OutlineInputBorder(),
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
