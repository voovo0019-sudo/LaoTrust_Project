# 🏛️ LaoTrust 프로젝트 수사 강령 (Constitution v2.0)

## 🏗️ Core Identity & Design Vision
- [cite_start]**정체성**: 라오스 No.1 신뢰 기반 생활 플랫폼 (전문 서비스 70 : 급구 알바 30) [cite: 112, 188, 229]
- [cite_start]**벤치마킹**: '숨고'의 세련된 화이트 무드 + '알바몬'의 직관적 기동성 [cite: 211, 212]
- **디자인 원칙**: 
  - [cite_start]**Base**: 배경은 깨끗한 **화이트(#FFFFFF)**로 개방감 확보 [cite: 226, 269]
  - [cite_start]**Point**: **인디고 블루(#3F51B5)**는 인증 배지, 핵심 버튼 등 '신뢰' 포인트에만 사용 [cite: 220, 226]
  - [cite_start]**확장성**: 모든 UI는 '아토믹 디자인(부품형)'으로 설계하여 부동산/자동차 확장 대비 [cite: 219, 238]
- [cite_start]**현지화**: 모든 텍스트는 i18n(`ko`, `en`, `lo`) 구조를 따르며 라오스어 길이 확장을 고려함 [cite: 189, 258]

## 🛠️ 기술 절대 원칙 (The Iron Rules)
1. [cite_start]**모노레포 & 모델 공유**: Flutter(App)와 Firebase(Server) 모델 통합 관리 [cite: 14, 184]
2. [cite_start]**바이브 코딩 금지**: 모든 작업 전 `Plan` 모드로 설계도 승인 후 진행 [cite: 9, 81, 196]
3. [cite_start]**토큰 경제성**: `mgrep`, `firebase CLI`를 직접 호출하여 지능 저하 방지 [cite: 76, 186]
4. [cite_start]**언어 정책**: 코드는 영어, 주석은 한국어와 영어를 병기함 [cite: 202, 259]

## 🚦 결정적 통제 (Hooks & Process)
- [cite_start]**PreToolUse**: 위험한 명령어나 기획 외 작업 전 반드시 형님의 승인 요청 [cite: 57, 193]
- [cite_start]**PostToolUse**: 파일 수정 후 테마 색상 및 i18n 언어 키 누락 여부 자가 검수 [cite: 60, 194]
- [cite_start]**#키 기억**: 새로운 규칙 발견 시 즉시 #키를 눌러 이 문서에 영구 기록 [cite: 37, 191]

## 🧠 사고 계층 (Thinking Hierarchy)
- **Normal**: 단순 UI 수정 및 오타 교정
- **Think Hard**: 페이지 기능 구현 및 데이터 스키마 설계
- [cite_start]**Ultra-think**: 결제, 매칭 알고리즘 등 복합 로직 (형님 명령 시 가동) [cite: 88, 161, 197]