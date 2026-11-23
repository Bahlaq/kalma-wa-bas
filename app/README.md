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

الملف [`../codemagic.yaml`](../codemagic.yaml) فيه workflowين:

| Workflow | الناتج |
|---|---|
| `kalma-android-apk` | APK debug للتثبيت على الجوال (بدون keystore) |
| `kalma-ios-testflight` | IPA + رفع لـ TestFlight |

**أندرويد:** لا يحتاج keystore حالياً — حمّل الـ APK من Artifacts وثبّته على الجوال.  
**iOS:** أضف مفتاح App Store Connect باسم التكامل `KalmaWaBas`، وشهادة Distribution + provisioning لـ `com.bahlaq.kalmaWaBas`، وأنشئ التطبيق في App Store Connect قبل أول رفع.

## الهيكل

- `lib/engine/` — منطق اللعبة (منقول من PWA)
- `lib/data/` — بنك اللاعبين + مسارات الصور
- `lib/screens/` — الرئيسية، الإعداد، المباراة
- `assets/players/` — صور اللاعبين المحلية
