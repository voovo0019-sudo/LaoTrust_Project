// Step 2: 위치·희망 시간 (70% 동선). / Location and preferred time.

import 'package:flutter/material.dart';
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
          const Text(
            '위치 및 희망 시간',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.location,
            decoration: const InputDecoration(
              labelText: '주소 또는 지역',
              hintText: '예: 비엔티안 시청 인근',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onChanged(state.copyWith(location: v)),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: state.wishedTime,
            decoration: const InputDecoration(
              labelText: '희망 방문 시간',
              hintText: '예: 오후 2시 이후',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onChanged(state.copyWith(wishedTime: v)),
          ),
        ],
      ),
    );
  }
}
