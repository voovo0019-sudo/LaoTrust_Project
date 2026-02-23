# LaoTrust (라오트러스트)

**"신뢰를 기술로 증명하고, 라오스를 연결한다."**

- **기획·화면 정의:** `docs/LaoTrust_기획요약_및_화면정의서_정리.md`
- **스토리보드:** `docs/LT-06_Storyboard.md`

## 실행 방법

```bash
flutter pub get
flutter run
```

### Firebase (미션02) 사용 시

실제 Firestore/전화번호 인증 사용 전에 프로젝트에 Firebase를 연결한다:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/firebase_options.dart`가 생성·덮어쓰기되며, 그 후 빌드 시 Firebase가 초기화된다. 미설정 시에는 플레이스홀더 옵션으로 앱만 실행된다.

## 질문지 화면 (Request Flow) 뼈대

홈 → **에어컨 수리** 아이콘 탭 시 **질문지 플로우**로 진입합니다.

| 경로 | 설명 |
|------|------|
| `lib/screens/request_flow/request_flow_screen.dart` | 질문지 컨테이너: 진행 바, ← 뒤로가기, PageView 슬라이드, 제출 시 완료 팝업 |
| `lib/screens/request_flow/request_flow_state.dart` | 작성 상태 + Local State Persistence (SharedPreferences) |
| `lib/screens/request_flow/steps/step1_symptom_step.dart` | Step 1: 증상 선택 (객관식, 다중 선택, 파란 테두리 강조) |
| `lib/screens/request_flow/steps/step2_location_time_step.dart` | Step 2: 위치·희망 시간 |
| `lib/screens/request_flow/steps/step3_photo_detail_step.dart` | Step 3: 사진 업로드 + 추가 요청사항 |

### LT-06 구현 지침 반영

- **슬라이드 전환:** PageView + `nextPage`/`previousPage` (300ms, easeInOut)
- **상태 보존:** `RequestFlowState.persist()` / `restore()` (SharedPreferences)
- **뒤로가기:** AppBar ← 클릭 시 이전 단계 또는 홈으로 복귀
