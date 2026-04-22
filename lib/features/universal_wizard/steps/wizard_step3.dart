// =============================================================================
// wizard_step3.dart
// Step3: 사진 업로드 + 위치/일정 입력 UI
// =============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../universal_wizard_state.dart';
import 'wizard_common.dart';

class WizardStep3 extends StatelessWidget {
  final UniversalWizardState state;
  final List<XFile> pickedImages;
  final String photoPrompt;
  final String Function(String key) l10n;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final void Function(int index) onRemoveImage;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final void Function(bool value) onUrgentChanged;
  final TextEditingController landmarkController;
  final TextEditingController movingFromController;
  final TextEditingController movingToController;
  final TextEditingController memoController;
  final VoidCallback onUseGps;

  const WizardStep3({
    super.key,
    required this.state,
    required this.pickedImages,
    required this.photoPrompt,
    required this.l10n,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemoveImage,
    required this.onPickDate,
    required this.onPickTime,
    required this.onUrgentChanged,
    required this.landmarkController,
    required this.movingFromController,
    required this.movingToController,
    required this.memoController,
    required this.onUseGps,
  });

  @override
  Widget build(BuildContext context) {
    const slots = 5;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            photoPrompt,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: kWizardRoyalBlue),
          ),
          const SizedBox(height: 8),
          Text(
            l10n('wizard_photo_upload_max').replaceAll('{n}', '$slots'),
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
                    side: const BorderSide(
                        color: kWizardRoyalBlue, width: 1.2),
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
                    side: const BorderSide(
                        color: kWizardRoyalBlue, width: 1.2),
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
            children: List.generate(slots, (i) {
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
                                ? Image.network(image!.path,
                                    fit: BoxFit.cover)
                                : Image.file(File(image!.path),
                                    fit: BoxFit.cover),
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
                            border: Border.all(
                                color: kWizardRoyalBlue, width: 1.2),
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
          const SizedBox(height: 24),
          if (state.categoryKey == 'expert_moving') ...[
            TextField(
              controller: movingFromController,
              decoration: wizardOutlineFieldDecoration(
                l10n('wizard_depth3_from_label'),
                hint: l10n('wizard_depth3_from_hint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: movingToController,
              decoration: wizardOutlineFieldDecoration(
                l10n('wizard_depth3_to_label'),
                hint: l10n('wizard_depth3_to_hint'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: landmarkController,
            decoration: wizardOutlineFieldDecoration(
              l10n('wizard_depth3_landmark_label'),
              hint: l10n('wizard_depth3_landmark_hint'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onUseGps,
            icon: const Icon(Icons.my_location),
            label: Text(l10n('wizard_depth3_use_gps_button')),
            style: OutlinedButton.styleFrom(
              foregroundColor: kWizardRoyalBlue,
              side: const BorderSide(color: kWizardRoyalBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
            ),
          ),
          if (state.step3Lat != null && state.step3Lng != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n('wizard_depth3_gps_coords')
                    .replaceAll('{lat}', '${state.step3Lat}')
                    .replaceAll('{lng}', '${state.step3Lng}'),
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          const SizedBox(height: 20),
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
                  child: Text(
                    state.preferredDateStr.isEmpty
                        ? l10n('wizard_depth3_pick_date')
                        : state.preferredDateStr,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickTime,
                  child: Text(
                    state.preferredTimeStr.isEmpty
                        ? l10n('wizard_depth3_pick_time')
                        : state.preferredTimeStr,
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
                style:
                    TextStyle(color: Colors.grey.shade800, fontSize: 13),
              ),
              Switch.adaptive(
                value: state.scheduleIsUrgent,
                onChanged: onUrgentChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: kWizardRoyalBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
}
