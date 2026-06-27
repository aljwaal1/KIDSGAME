KIDSGAME Complete Fix v2

انسخ محتويات هذه الحزمة فوق المستودع مباشرة أو ارفعها بأداة الرفع.
الحزمة تحتوي ملفات فعلية في مسارات lib/... وليست مجرد سكربت.

تحل:
- نقص lib/services/score_service.dart
- نقص lib/services/sound_service.dart
- نقص ألعاب الذكاء الخمس
- ترجع إكس أو مع الكمبيوتر
- ترجع بزل الأرقام 3x3 و 4x4
- ترجع فقاعات الحروف المحسنة
- تستبدل main.dart بنسخة آمنة بدون dot-shorthands

بعد الرفع شغل:
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --release
