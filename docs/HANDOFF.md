# Qeran — Handoff (وين وصلنا)

> **الغرض:** الطبقة غير المستنتَجة من حالة المشروع — النية، القرارات، الخطوات الجاية، الـ gotchas، بنود الباك إند. حالة الكود نفسها (أي شاشة موحّدة/لأ) تُستنتَج من الكود + legacy-grep — لا تُكتب هنا (تبيت قديمة).
> اقرأه أول شي كل جلسة (أنا الويب + Claude Code). حدّثه نهاية كل مهمة.
> آخر تحديث: 5 يونيو 2026

---

## 🎯 النية / المهمة الحالية
التركيز انتقل من الخطّابة إلى **مراجعة الالتزام بالـ design system في تطبيق المستخدم (compliance sweep)** — نلف شاشة شاشة ونرجّع كل شي للهوية والتوكنز. الخطّابة **محجوبة** على ردود طارق على توثيق v2.2.

## 🗺️ الخطوات الجاية (بالأولوية)
1. **هجرة auth/ الكاملة ⭐ (جارية)** — أكبر تجمّع legacy (~150 ref: login/register/oath/forgot-reset/whatsapp/country-picker/OTP/social). فيه `CustomButton` + `AppTextFormField` ممنوعين + Material `AlertDialog` داخل `share_with_matchmaker_button`. خطوات فرعية — **انظر قسم «🔧 هجرة auth — التقدّم» أدناه.**
2. **باقي الـ sweep** — onboarding، notifications، subscriptions (الـ widgets الـ legacy)، questionnaire widgets… شاشة شاشة (legacy-grep gate يخدم هذا).
3. **الخطّابة** — محجوبة على ردود طارق (v2.2) — انظر بنود الباك إند.
4. **الاهتمامات — تاب التوافق:** تعديل شكلي بسيط حسب فيجما — لاحقاً.
5. **الإعدادات:** إكمال المتبقّي.
6. **الباقات:** ربط ببوابات الدفع.

---

## 🔒 القرارات الثابتة (الكود لا يعرفها — احترمها)
- **اللون:** الخلفية أبيض ناعم `#FEFCFA` — قرار نهائي (تجاوز مقصود لدليل الهوية `#FCEDDD`). **معمول ومـcommitted** (`4ee10cd`) — شجرة العمل نظيفة. (الادعاء القديم إنه unstaged كان غلط، أُزيل.)
- **OTP دايماً LTR:** خانات كود الـ OTP تنعرض يسار→يمين بكل اللغات (أول خانة على اليسار) لأن الأكواد الرقمية تُقرأ LTR. مطبّقة عبر `textDirection` على الـ Row نفسه (مش الـ Directionality widget الممنوع). (`878f5cc`)
- **`wineLight` `#4A1F38`:** توكن جديد لون لتدرّجات الواين ثنائية اللون (يُقرَن مع `wine`). (`f26e078`)
- **swipe-deck ميت ومحذوف** — `discovery/` هو الـ deck الحي؛ `home_screen.dart` يحتضن `DiscoveryView`. (`7a8ec1f`)
- **AUTH FIELD STYLE (مهم — لا توحّده):** حقول auth = `pill` + بلا border + ظل `e1` (تعبئة `paper` بيضاء، حلقة `danger` على الخطأ فقط). يختلف **عمداً** عن أسطح غير-auth (questionnaire/discovery/checkout) = `paper` + `hairline border`. معالجتان مقصودتان — لا "توحّدهما". (`5b80df4`)
- **labels الحقول:** نمط فيجما = label **فوق** الحقل + hint **داخله**؛ يحملها `QeranTextField.label` / `AuthPasswordField.labelText`.
- **توكنز جديدة:** `inkFaint` (#B3A8AF — أفتح محايد، للـ hints والأيقونات الناعمة)؛ `appleBlack` (#000000 — الأسود الوحيد المسموح بالتطبيق، glyph Apple فقط).
- **أزرار CTA (recovery/login/register):** `QeranButton` `primaryWine` (واين + نص أبيض).
- **العين المدمجة (محسوم، كان مؤجّل):** `AuthPasswordField` تبنّى `showObscureToggle` المدمج؛ حُذف `obscurePasswordNotifier`/`onToggleVisibility` من الـ widget + login/register/reset controllers. (sub-step c)
- **phone + `CountryCodePicker` (محسوم، كان مؤجّل b2):** هوجرا معاً بنفس معالجة الحقل. (`60f85f5`)
- **السؤال vs المضي:** اسأل على أي قرار (دلالي أو تجميلي). فقط التعديلات المحددة تماماً تمشي مباشرة. (الافتراض القديم "امشِ بالتجميلي" ملغى.)
- **Figma = الشكل، الهوية = الألوان.** صفر تسامح — كل شيء من الـ design system.

---

## ⚠️ Gotchas (تنبيهات)
- **رسائل الـ commit بتكذب:** commits قديمة تدّعي توحيد auth/onboarding — لسا legacy. تأكّد من الكود دايماً.
- الدين التقني على جهة المستخدم؛ الخطّابة ~95% موحّدة أصلاً.
- `MATCHMAKER_DIAGNOSTIC.md` القديم stale — أشياء قال "ناقصة" صارت معمولة. ثق بالكود.
- **Profile hub — تاب العرض ما بيتحدّث بعد الحفظ:** `MyProfileCubit` لسا داخل `ProfileSelfView` (مش مرفوع فوق الـ `TabBarView` بالـ hub)، فالتابّان لهما instances منفصلة. الإصلاح المقترح: ارفع `MyProfileCubit` فوق الـ hub ليتشارك التابّان نفس الـ cubit ويعيد التحميل بعد الحفظ. (متحقَّق منه هذه الجلسة — لسا غير معمول.)
- **reset_pass متحقَّق:** بعد تبنّي العين المدمجة (sub-step c/d) الشاشة تُصرّف صح والعين تبدّل — لا إجراء مطلوب.
- **`'auth.country_search_hint'` كنص خام** في `country_code_picker` (مش عبر `LocaleKeys`) — موجود مسبقاً؛ تحقّق إنه يُحَل AR+EN.

---

## ⏸️ مؤجّل (Deferred)
- **ملفّا اختبار likes قديمان** (`match_card_stage0_test`, `likes_cubit_test`) متأخران عن refactor `32ba51d` (حُذف `PhotoExchangeActionRow`، تغيّرت توقيعات الـ cubit/MatchCard). **الإنتاج نظيف** (`flutter analyze lib` = 0 errors) — اختبارات فقط، تحتاج تحديث/حذف.
- **`share_with_matchmaker_button`:** الـ `_confirmDialog` ملف مختلط نظامين (الزر الرئيسي `QeranButton` بس الـ dialog لسا Material + `AppColors`) — يحتاج هجرة كاملة، مش إصلاح سطر.

---

## 📨 معلّق على طارق (Backend)
| البند | الحالة |
|-------|--------|
| **الخطّابة v2.2 — بطاقة الموحّدة:** هل ترجع `age` + `answers[]` فعلاً؟ | معلّق — **يحجب شغل بطاقات الخطّابة** |
| **subscription:** nested `{planName, expiresAt}` ولا flat keys؟ | معلّق |
| `GET /users/subscription-plans` منشور؟ + فلتر `?planId=` شغّال؟ | معلّق |
| (product) notes endpoint للأعضاء؟ | معلّق — UI فيجما بلا باك إند |
| (product) بلد الزميلة (colleague country)؟ | معلّق — مش بالـ DTO |
| (product) unread لكل بطاقة بقوائم الأعضاء؟ | معلّق — موجود بالمحادثات فقط |
| مسارات الصور (حذف/تعيين رئيسية) | معلّق — تعارض user-images / profile-images |
| Help & Support endpoint | معلّق — الإرسال وهمي |
| Terms & Privacy — النص الحقيقي | معلّق |
| Verified-badge flag | معلّق — hardcoded حالياً |
| Delete-account flow | غير مؤكد |
| حد الماتشات | backend-only — نأكد الرقم |
| بوابات الدفع | معلّق — الباقات تجلب بيانات بس بلا دفع |

---

## 📍 هذه الجلسة (sweep الـ design system — commits على main)
- `7a8ec1f` — حذف swipe-deck الميت (~65 legacy ref راحوا).
- `1299c8b` — حذف 3 `Directionality` widgets ممنوعة (otp + 2 discovery).
- `c932de5` + `f26e078` — إصلاحات توكنز: أضفنا `wineLight`، وربطنا الـ radii الشاردة بالـ scale (22→card، أشرطة 2px→pill).
- `878f5cc` — خانات OTP مقفولة LTR بكل اللغات.
- **legacy refs:** ~390 → ~315. ثم بدأت هجرة `auth/` (تحت).

---

## 🔧 هجرة auth — التقدّم (sub-steps)
**معمول:**
- `079d077` — أضفنا `QeranTextField` للـ DS (بديل `AppTextFormField`؛ creamSurface fill + control radius + عين `showObscureToggle` مدمجة، RTL-aware).
- `a19ce3d` — توكن `appleBlack` (#000000) = الأسود الوحيد المسموح بالتطبيق، استثناء التزام بعلامة Apple (HIG) — على glyph الـ Apple فقط.
- `0a4681a` — **sub-step a:** هجرة الـ leaves البصرية المشتركة (`or_divider`, `auth_footer_link`, `auth_title_subtitle`, `social_login_buttons`, `oath_title_ornament`؛ `auth_back_button` + `auth_logo_header` نظاف أصلاً).
- `95b4d88` — **sub-step b:** هجرة wrappers الإيميل + كلمة المرور للـ `QeranTextField`.
- `60f85f5` — **sub-step b2:** هجرة حقل الهاتف + `CountryCodePicker` معاً.
- `3f4fd19` — أسطح الحقول/الكروت `creamSurface` → `paper` أبيض + `hairline border` (مراجعة تصميم).
- `e3ddd3d` + `5b80df4` — **sub-step c:** login/register يطابقوا فيجما (label فوق الحقل، تبنّي العين المدمجة `showObscureToggle`، حذف الـ notifier من الـ controllers)؛ والحقول صارت `pill`/borderless + ظل `e1` + hint الاسم من فيجما.
- `657dee9` — hints أصغر/أفتح + توكن `inkFaint` (مراجعة تصميم).
- `469e9c5` — disc جوجل → `paper` أبيض + ظل `e2` (مراجعة تصميم).
- `e812c8f` — **sub-step d:** هجرة شاشتي forgot/reset password.

**الحالة:** 0 ✅ · a ✅ · b ✅ · b2 ✅ · c ✅ · d ✅
**الباقي:** e (whatsapp/OTP + إصلاح deprecation `otp_input_row:84` background) · f (oath) · g (upload-image).
