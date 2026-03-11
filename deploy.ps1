# 라오스 파트너 시연용 최종 배포 (사령관 승인)
# 실행: .\deploy.ps1 또는 PowerShell에서 복사 후 실행
Set-Location $PSScriptRoot
flutter clean
flutter build web
firebase deploy
