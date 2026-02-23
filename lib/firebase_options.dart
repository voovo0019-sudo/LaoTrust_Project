// LT-08 미션02: Firebase 연동용 옵션.
// 실제 배포 전 터미널에서: dart pub global activate flutterfire_cli && flutterfire configure
// 위 명령이 이 파일을 프로젝트용으로 덮어쓴다. 아래는 미설정 시 앱만 뜨게 하는 플레이스홀더다.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'laotrust-placeholder',
    storageBucket: 'laotrust-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'laotrust-placeholder',
    storageBucket: 'laotrust-placeholder.appspot.com',
  );
}
