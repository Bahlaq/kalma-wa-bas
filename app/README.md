# كلمة وبس — Flutter

تطبيق Flutter أصلي للعبة «كلمة وبس» (أندرويد / iOS عبر Codemagic).

## محلياً (اختياري)

```sh
cd app
flutter pub get
flutter test
flutter run
```

## Codemagic

الملف [`../codemagic.yaml`](../codemagic.yaml) يبني APK أندرويد بعد `flutter test`. اربط المستودع في Codemagic واختر workflow `kalma-android`.

## الهيكل

- `lib/engine/` — منطق اللعبة (منقول من PWA)
- `lib/data/` — بنك اللاعبين + مسارات الصور
- `lib/screens/` — الرئيسية، الإعداد، المباراة
- `assets/players/` — صور اللاعبين المحلية
