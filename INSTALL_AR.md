# كيف تحوّل المشروع إلى تطبيق حقيقي (APK / iOS)

## الطريق 1: أندرويد APK — من حاسوبك (Windows/Mac/Linux)

1. ثبّت Flutter SDK من: https://docs.flutter.dev/get-started/install
2. تحقق:
```bash
flutter doctor
flutter doctor --android-licenses
```
3. من مجلد المشروع:
```bash
cd hr_app
flutter pub get
flutter run              # للتجربة على هاتف موصول بـ USB أو محاكي
flutter build apk --release   # ينتج ملف التثبيت
```
4. الملف الناتج:
```
build/app/outputs/flutter-apk/app-release.apk
```
انسخه لهاتفك وثبّته (فعّل "تثبيت من مصادر غير معروفة").

> للنشر على Google Play بدل `apk` ابنِ `flutter build appbundle --release` وارفع ملف `.aab` على Play Console.

## الطريق 2: بدون تثبيت Flutter — بناء سحابي مجاني (GitHub Actions)

1. أنشئ حساب GitHub وارفع مجلد `hr_app` إلى مستودع جديد.
2. ملف البناء موجود جاهزاً في: `.github/workflows/android.yml`
3. من GitHub: تبويب Actions ← شغّل Build APK ← حمّل الـ APK من Artifacts.
4. لا يحتاج حاسوباً قوياً ولا تثبيت أي شيء.

## الطريق 3: آيفون iOS — يحتاج Mac أو سحابة

- على Mac:
```bash
flutter build ipa --release
```
ثم ارفع عبر Transporter إلى App Store Connect / TestFlight.
- بدون Mac: استخدم **Codemagic** (مجاني جزئياً): اربط مستودع GitHub ← اختر Flutter iOS ← وقّع بشهادة Apple Developer (99$/سنة) ← حمّل IPA أو وزّع عبر TestFlight.

## قبل البناء: تخصيصات إجبارية (10 دقائق)

1. اسم التطبيق والحزمة في `android/app/build.gradle` (مثل `com.company.hr`) وفي Xcode Bundle ID.
2. الأيقونة: ضع صورتك `assets/icon.png` ثم:
```bash
flutter pub add flutter_launcher_icons
flutter pub run flutter_launcher_icons
```
3. اسم الشركة والشعار والألوان (راجع README).
4. للإشعارات Push: أنشئ مشروع Firebase وأضف `google-services.json` (أندرويد) و`GoogleService-Info.plist` (iOS).

## الأسئلة الشائعة

- **هل أحتاج حساب مطور؟** للتجربة الداخلية لا. للنشر: Google Play (25$ مرة واحدة) / Apple (99$/سنة).
- **جهازي Windows وأريد نسخة iPhone؟** استخدم Codemagic — لا بديل عملي آخر.
- **التطبيق الحالي يعمل دون خادم؟** نعم، ببيانات تجريبية. اربط `lib/core/api.dart` لاحقاً دون إعادة البناء الكامل.
