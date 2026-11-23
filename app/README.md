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
| `kalma-android-apk` | APK أندرويد موقّع |
| `kalma-ios-testflight` | IPA + رفع لـ TestFlight |

**أندرويد:** ارفع keystore في Codemagic باسم المرجع `kalma_keystore`.  
**iOS:** أضف مفتاح App Store Connect باسم التكامل `KalmaWaBas`، وشهادة Distribution + provisioning لـ `com.bahlaq.kalmaWaBas`، وأنشئ التطبيق في App Store Connect قبل أول رفع.

## الهيكل

- `lib/engine/` — منطق اللعبة (منقول من PWA)
- `lib/data/` — بنك اللاعبين + مسارات الصور
- `lib/screens/` — الرئيسية، الإعداد، المباراة
- `assets/players/` — صور اللاعبين المحلية
