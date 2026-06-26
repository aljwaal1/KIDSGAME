# إصلاح KIDSGAME v2

هذا الإصلاح يعالج الأخطاء التي ظهرت في GitHub Actions:

1. `Target of URI doesn't exist: ../services/...`
   - أضفت ملفات الخدمات المطلوبة داخل `lib/services`.
   - غيرت ملفات الألعاب الجديدة لتستخدم imports ثابتة من اسم الحزمة:
     `package:kids_games_arena/services/...`

2. خطأ `dot-shorthands language feature`
   - استبدلت `lib/main.dart` بنسخة آمنة لا تستخدم أي صيغة Dart حديثة غير مدعومة.
   - لا تحتاج رفع minimum SDK إلى Dart 3.10.

## طريقة التطبيق

1. فك الضغط عن هذا الملف.
2. انسخ محتوياته إلى جذر مستودع KIDSGAME.
3. شغّل:

```bash
python apply_kidsgame_hotfix_v2.py
```

4. ارفع التغييرات إلى GitHub.
5. شغّل GitHub Actions.

## الملفات التي يستبدلها الإصلاح

- `lib/main.dart`
- `lib/screens/home_page.dart`
- `lib/services/score_service.dart`
- `lib/services/sound_service.dart`
- ملفات الألعاب الجديدة داخل `lib/games`

