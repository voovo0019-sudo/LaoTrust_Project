# 1. .env 파일에서 연료(키) 추출
$env_file = Get-Content .env | ConvertFrom-StringData
$api_key = $env_file.GOOGLE_TRANSLATE_API_KEY

if (-not $api_key) {
    Write-Host "🚨 에러: .env 파일에서 키를 찾을 수 없습니다!" -ForegroundColor Red
    exit
}

Write-Host "🚀 연료 주입 완료(Key 확인됨)! 함선 배포 작전을 시작합니다..." -ForegroundColor Cyan
flutter clean
flutter build web --dart-define=GOOGLE_TRANSLATE_API_KEY=$api_key
firebase deploy --only hosting
Write-Host "✅ 배포 완벽하게 종료되었습니다! 이제 번역이 잘 될 겁니다." -ForegroundColor Green
