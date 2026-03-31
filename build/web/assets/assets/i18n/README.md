# LT-09 다국어 금고 (i18n) / Language Vault

한국어(ko), 영어(en), 라오어(lo) 3개국어 JSON 파일 구조.

## 파일

| 파일 | 설명 |
|------|------|
| `ko.json` | 한국어 문자열 |
| `en.json` | English strings |
| `lo.json` | ພາສາລາວ (Lao) strings |

## 규칙

- 모든 파일은 **동일한 키**를 가져야 함. 키 추가 시 세 파일 모두에 추가.
- 앱에서 사용: `context.l10n('key')` (lib/core/app_localizations.dart).
- 로드: lib/core/locale_service.dart 의 `loadStringsForLocale(locale)`.

## Handover

새 언어 추가: supportedLocales + 여기 새 {code}.json 추가.
