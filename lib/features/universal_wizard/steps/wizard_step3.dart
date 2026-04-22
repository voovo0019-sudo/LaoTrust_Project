// =============================================================================
// wizard_step3.dart
// v5.1: Step3LocationMode 기반 3가지 UI 자동 분기
// onsite(현장형) / routing(이동형) / flexible(선택형)
// =============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../universal_wizard_config.dart';
import '../universal_wizard_state.dart';
import 'wizard_common.dart';

class WizardStep3 extends StatelessWidget {
  final UniversalWizardState state;
  final Set<String> fieldErrors;
  final Step3LocationMode step3Mode;
  final List<XFile> pickedImages;
  final int photoSlotCount;
  final String photoPrompt;
  final String Function(String key) l10n;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final void Function(int index) onRemoveImage;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final void Function(bool value) onUrgentChanged;
  final void Function(ServiceModeChoice? choice) onServiceModeChanged;
  final TextEditingController landmarkController;
  final TextEditingController movingFromController;
  final TextEditingController movingToController;
  final TextEditingController memoController;
  final VoidCallback onUseGps;

  const WizardStep3({
    super.key,
    required this.state,
    required this.fieldErrors,
    required this.step3Mode,
    required this.pickedImages,
    required this.photoSlotCount,
    required this.photoPrompt,
    required this.l10n,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemoveImage,
    required this.onPickDate,
    required this.onPickTime,
    required this.onUrgentChanged,
    required this.onServiceModeChanged,
    required this.landmarkController,
    required this.movingFromController,
    required this.movingToController,
    required this.memoController,
    required this.onUseGps,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 섹션 타이틀
          Text(
            l10n('wizard_depth3_section_title'),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            l10n('wizard_depth3_section_desc'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),

          // ── flexible 모드: 서비스 방식 선택 카드 (최상단)
          if (step3Mode == Step3LocationMode.flexible) ...[
            _buildServiceModeSelector(context),
            const SizedBox(height: 24),
          ],

          // ── 사진 업로드 섹션
          _buildPhotoSection(),
          const SizedBox(height: 24),

          // ── 위치 정보 섹션 (모드별 분기)
          _buildLocationSection(),
          const SizedBox(height: 20),

          // ── 일정 섹션 (공통)
          _buildScheduleSection(),
          const SizedBox(height: 16),

          // ── 추가 메모 (공통)
          TextField(
            controller: memoController,
            decoration: InputDecoration(
              labelText: l10n('wizard_extra_request_label'),
              hintText: l10n('wizard_extra_request_hint'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // flexible 모드: 서비스 방식 선택 카드
  // ═══════════════════════════════════════════════════
  Widget _buildServiceModeSelector(BuildContext context) {
    final choices = _getChoicesForCategory();
    final hasError = fieldErrors.contains('serviceMode');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n('wizard_step3_mode_title'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: hasError ? Colors.red.shade600 : kWizardRoyalBlue,
          ),
        ),
        const SizedBox(height: 4),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n('wizard_field_service_mode_required'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: hasError
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                )
              : null,
          padding: hasError ? const EdgeInsets.all(12) : EdgeInsets.zero,
          child: Column(
            children:
                choices.map((choice) => _buildModeCard(choice)).toList(),
          ),
        ),
      ],
    );
  }

  List<_ModeCardData> _getChoicesForCategory() {
    switch (state.categoryKey) {
      case 'expert_beauty':
        return [
          const _ModeCardData(
            choice: ServiceModeChoice.visit,
            icon: Icons.home_outlined,
            titleKey: 'beauty_visit_home',
            descKey: 'wizard_step3_mode_visit_desc',
          ),
          const _ModeCardData(
            choice: ServiceModeChoice.goToShop,
            icon: Icons.store_outlined,
            titleKey: 'beauty_visit_shop',
            descKey: 'wizard_step3_mode_go_to_shop_desc',
          ),
        ];
      case 'expert_tutoring':
        return [
          const _ModeCardData(
            choice: ServiceModeChoice.remote,
            icon: Icons.videocam_outlined,
            titleKey: 'tutor_class_online',
            descKey: 'wizard_step3_mode_remote_desc',
          ),
          const _ModeCardData(
            choice: ServiceModeChoice.visit,
            icon: Icons.home_outlined,
            titleKey: 'tutor_class_visit',
            descKey: 'wizard_step3_mode_visit_desc',
          ),
          const _ModeCardData(
            choice: ServiceModeChoice.goToShop,
            icon: Icons.school_outlined,
            titleKey: 'tutor_class_center',
            descKey: 'wizard_step3_mode_go_to_shop_desc',
          ),
        ];
      case 'expert_vehicle':
        return [
          const _ModeCardData(
            choice: ServiceModeChoice.visit,
            icon: Icons.directions_car_outlined,
            titleKey: 'wizard_step3_mode_visit',
            descKey: 'wizard_step3_mode_visit_desc',
          ),
          const _ModeCardData(
            choice: ServiceModeChoice.goToShop,
            icon: Icons.build_outlined,
            titleKey: 'wizard_step3_mode_go_to_shop',
            descKey: 'wizard_step3_mode_go_to_shop_desc',
          ),
        ];
      default: // expert_business 포함 기본
        return [
          const _ModeCardData(
            choice: ServiceModeChoice.remote,
            icon: Icons.wifi_outlined,
            titleKey: 'wizard_step3_mode_remote',
            descKey: 'wizard_step3_mode_remote_desc',
          ),
          const _ModeCardData(
            choice: ServiceModeChoice.visit,
            icon: Icons.home_outlined,
            titleKey: 'wizard_step3_mode_visit',
            descKey: 'wizard_step3_mode_visit_desc',
          ),
        ];
    }
  }

  Widget _buildModeCard(_ModeCardData data) {
    final isSelected = state.step3ServiceMode == data.choice;
    return GestureDetector(
      onTap: () {
        if (state.step3ServiceMode == data.choice) {
          onServiceModeChanged(null); // 같은 거 누르면 해제
        } else {
          onServiceModeChanged(data.choice);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? kWizardRoyalBlue.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? kWizardRoyalBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(data.icon,
                color: isSelected ? kWizardRoyalBlue : Colors.grey.shade500,
                size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n(data.titleKey),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? kWizardRoyalBlue
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n(data.descKey),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: kWizardRoyalBlue, size: 22),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 사진 업로드 섹션 (공통)
  // ═══════════════════════════════════════════════════
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photoPrompt,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: kWizardRoyalBlue),
        ),
        const SizedBox(height: 8),
        Text(
          l10n('wizard_photo_upload_max').replaceAll('{n}', '$photoSlotCount'),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n('wizard_photo_pick_gallery')),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kWizardRoyalBlue,
                  side:
                      const BorderSide(color: kWizardRoyalBlue, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n('wizard_photo_pick_camera')),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kWizardRoyalBlue,
                  side:
                      const BorderSide(color: kWizardRoyalBlue, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(photoSlotCount, (i) {
            final hasPhoto = i < pickedImages.length;
            final image = hasPhoto ? pickedImages[i] : null;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: kWizardRoyalBlue.withValues(alpha: 0.4),
                        width: 1.2),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: kIsWeb
                              ? Image.network(image!.path, fit: BoxFit.cover)
                              : Image.file(File(image!.path), fit: BoxFit.cover),
                        )
                      : Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.grey.shade600, size: 34),
                ),
                if (hasPhoto)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: InkWell(
                      onTap: () => onRemoveImage(i),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: kWizardRoyalBlue, width: 1.2),
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: kWizardRoyalBlue),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // 위치 정보 섹션 (모드별 분기)
  // ═══════════════════════════════════════════════════
  Widget _buildLocationSection() {
    switch (step3Mode) {
      case Step3LocationMode.routing:
        return _buildRoutingLocation();
      case Step3LocationMode.flexible:
        // remote 선택 시 위치 숨김
        if (state.step3ServiceMode == ServiceModeChoice.remote) {
          return const SizedBox.shrink();
        }
        return _buildOnsiteLocation();
      case Step3LocationMode.onsite:
        return _buildOnsiteLocation();
    }
  }

  // 이동형 (이사): 출발지 + 도착지
  Widget _buildRoutingLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: movingFromController,
          decoration: wizardOutlineFieldDecoration(
            l10n('wizard_depth3_from_label'),
            hint: l10n('wizard_depth3_from_hint'),
            isRequired: true,
            hasError: fieldErrors.contains('movingFrom'),
            errorText: l10n('wizard_field_required'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: movingToController,
          decoration: wizardOutlineFieldDecoration(
            l10n('wizard_depth3_to_label'),
            hint: l10n('wizard_depth3_to_hint'),
            isRequired: true,
            hasError: fieldErrors.contains('movingTo'),
            errorText: l10n('wizard_field_required'),
          ),
        ),
        const SizedBox(height: 12),
        _buildGpsButton(),
      ],
    );
  }

  // 현장형 + flexible(방문/샵): GPS + 주소
  Widget _buildOnsiteLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n('wizard_step3_location_title'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: landmarkController,
          decoration: wizardOutlineFieldDecoration(
            l10n('wizard_depth3_landmark_label'),
            hint: l10n('wizard_depth3_landmark_hint'),
            isRequired: true,
            hasError: fieldErrors.contains('landmark'),
            errorText: l10n('wizard_field_required'),
          ),
        ),
        const SizedBox(height: 12),
        _buildGpsButton(),
      ],
    );
  }

  Widget _buildGpsButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onUseGps,
          icon: const Icon(Icons.my_location),
          label: Text(l10n('wizard_depth3_use_gps_button')),
          style: OutlinedButton.styleFrom(
            foregroundColor: kWizardRoyalBlue,
            side: const BorderSide(color: kWizardRoyalBlue),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        ),
        if (state.step3Lat != null && state.step3Lng != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n('wizard_depth3_gps_coords')
                  .replaceAll('{lat}', '${state.step3Lat}')
                  .replaceAll('{lng}', '${state.step3Lng}'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // 일정 섹션 (공통)
  // ═══════════════════════════════════════════════════
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n('wizard_depth3_schedule_title'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: kWizardRoyalBlue),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPickDate,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: fieldErrors.contains('preferredDate')
                        ? Colors.red.shade400
                        : kWizardRoyalBlue,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  state.preferredDateStr.isEmpty
                      ? l10n('wizard_depth3_pick_date')
                      : state.preferredDateStr,
                  style: TextStyle(
                    color: fieldErrors.contains('preferredDate')
                        ? Colors.red.shade400
                        : kWizardRoyalBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onPickTime,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: fieldErrors.contains('preferredTime')
                        ? Colors.red.shade400
                        : kWizardRoyalBlue,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  state.preferredTimeStr.isEmpty
                      ? l10n('wizard_depth3_pick_time')
                      : state.preferredTimeStr,
                  style: TextStyle(
                    color: fieldErrors.contains('preferredTime')
                        ? Colors.red.shade400
                        : kWizardRoyalBlue,
                  ),
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
                l10n('wizard_schedule_urgency'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              state.scheduleIsUrgent
                  ? l10n('wizard_schedule_urgent')
                  : l10n('wizard_schedule_normal'),
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
            ),
            Switch.adaptive(
              value: state.scheduleIsUrgent,
              onChanged: onUrgentChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: kWizardRoyalBlue,
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// 내부 데이터 클래스
// ═══════════════════════════════════════════════════
class _ModeCardData {
  const _ModeCardData({
    required this.choice,
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });
  final ServiceModeChoice choice;
  final IconData icon;
  final String titleKey;
  final String descKey;
}
