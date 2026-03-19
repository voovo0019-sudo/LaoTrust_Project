// Step 2: 위치·희망 시간 (70% 동선). / Location and preferred time.

import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import '../request_flow_state.dart';

class Step2LocationTimeStep extends StatelessWidget {
  const Step2LocationTimeStep({
    super.key,
    required this.state,
    required this.onChanged,
  });
  final RequestFlowState state;
  final ValueChanged<RequestFlowState> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('request_step2_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.location,
            decoration: InputDecoration(
              labelText: context.t('request_location_label'),
              hintText: context.t('request_location_hint'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => onChanged(state.copyWith(location: v)),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: state.wishedTime,
            decoration: InputDecoration(
              labelText: context.t('request_wished_time_label'),
              hintText: context.t('request_wished_time_hint'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => onChanged(state.copyWith(wishedTime: v)),
          ),
        ],
      ),
    );
  }
}
