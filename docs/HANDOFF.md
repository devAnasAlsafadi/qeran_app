# Qeran — Handoff (وين وصلنا)

> **الغرض:** الطبقة غير المستنتَجة من حالة المشروع — النية، القرارات، الخطوات الجاية، الـ gotchas، بنود الباك إند. حالة الكود نفسها (أي شاشة موحّدة/لأ) تُستنتَج من الكود + legacy-grep — لا تُكتب هنا (تبيت قديمة).
> اقرأه أول شي كل جلسة (أنا الويب + Claude Code). حدّثه نهاية كل مهمة.
> آخر تحديث: 6 يونيو 2026

---

## 🎯 النية / المهمة الحالية
التركيز الحالي = **الخطّابة: إعادة تصميم بطاقة العضو + توحيد 3 ميزات (سلسلة M3)**. وصلت **وثيقة الباك إند الموحّدة من طارق** ففُكّ الحجب القديم. M3a–c **معمولة**؛ الجاي M3d/e/f (تفاصيل بقسم «🧩 الخطّابة — M3»). بالتوازي **sweep الـ design system بتطبيق المستخدم** مستمر (auth ✅ مكتملة؛ بقي onboarding/notifications/subscriptions/questionnaire/settings).

## 🗺️ الخطوات الجاية (بالأولوية)
1. ~~**هجرة auth/ الكاملة**~~ ✅ **مكتملة** (0→g كلها معمولة — انظر «🔧 هجرة auth — التقدّم»). يبقى فقط: `share_with_matchmaker_button._confirmDialog` (مؤجّل — انظر Deferred).
2. **باقي الـ sweep (بالتوازي / بعد M3)** — onboarding، notifications، subscriptions (widgets legacy: `discount_code_field`/`pricing_segment`/`feature_row`/`plan_visual`…)، questionnaire widgets، settings (بسيط). شاشة شاشة (legacy-grep gate يخدم هذا).
3. **الخطّابة — سلسلة M3 ⭐ (الجاري/الأولوية):** M3a–c ✅. الجاي بالترتيب: **M3d** (الملاحظات — full-stack، الباك إند جاهز)، **M3e** (عرض → سلك تنقّل واحد للشاشة الموجودة + **حذف** action-bar الموافقة من داخل الملف)، **M3f** (مرآة الاهتمامات — 3 تابات، إعادة استخدام كروت تطبيق المستخدم read-only؛ الأكبر، يعتمد على M3e). تفاصيل بقسم «🧩 الخطّابة — M3».
4. **الاهتمامات (تطبيق المستخدم) — تاب التوافق:** تعديل شكلي بسيط حسب فيجما — لاحقاً.
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
- **`QeranRadii.xs` = 6:** أصغر توكن radius (الـ DS ما كان فيه واحد صغير) — للضوابط الصغيرة مثل checkbox القَسَم. (`85c3d63`)
- **كرت القَسَم (oath):** السطح = تدرّج `paper → creamSurface` (مش الـ hex المؤجّل #FFFBF5/#F4E9DC) + `panelR` + ظل `e3`. (`85c3d63`)
- **خانات OTP تبقى بحدود (NOT pill):** صناديق الرقم-الواحد تحتاج حدّاً مرئياً — `paper` + `hairline` + `controlR` + رقم `headline`؛ معالجة مختلفة عمداً عن حقول النص الـ pill. (`8b87d07`)
- **السؤال vs المضي:** اسأل على أي قرار (دلالي أو تجميلي). فقط التعديلات المحددة تماماً تمشي مباشرة. (الافتراض القديم "امشِ بالتجميلي" ملغى.)
- **Figma = الشكل، الهوية = الألوان.** صفر تسامح — كل شيء من الـ design system.
- **— الخطّابة (قرارات M3، حرجة وغير مستنتَجة):**
  - **عرض الملف — معكوس:** الخطّابة تستخدم `GET /matchmaker/users/{id}/profile` (`ProfileResponseDto`، `OwnerImage` فيه `isApproved`، **بلا** `isBlurred`). **ممنوع** `/discovery/profiles/{id}` — يرجّع `matchingScore` بلا معنى **و**يُحتسب على حدّ المشاهدات اليومي للمستخدم. التوحيد = **renderers مشتركة** (`PlacementRenderer`/`ProfileHeaderGallery`) مش شاشة مشتركة. ستاك ملف الخطّابة **موجود وصحيح**.
  - **الملف = عرض فقط:** action-bar الموافقة/الرفض **داخل** الملف **يُحذف** — كل الموافقة/الرفض على **الكرت** (M3b). ينطبق أينما فُتح الملف (عرض من القائمة + نقر كرت الاهتمامات). احذف سقالة `ProfileEntrySource.matchmaker` الميتة.
  - **توكنز/widgets جديدة بالـ DS:** `softFill` (`#1A431C33`، ~10% واين، تعبئة chip ناعمة) + `QeranButtonVariant.neutral` (الـ variants صارت **7 مش 6** — `DESIGN.md` stale بهالنقطة) + `QeranSheetHandle` مشترك + `MatchmakerCardAnswersBlock` (يعيد استخدامه M3f).
  - **قاعدة أزرار الكرت:** **زر مملوء واحد** `primaryWine` لكل قائمة (pending = موافقة، الباقي = مراسلة)، والباقي chips `neutral`؛ داخل `Wrap` فالـ labels ما تنقص أبداً.

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
| `GET /users/subscription-plans` منشور؟ + فلتر `?planId=` شغّال؟ | معلّق |
| **الخطّابة — شكل رد** `GET …/{id}/chat`: `data:123` ولا `{conversationId}`؟ | معلّق — **non-blocking** (parser دفاعي يغطّي الاثنين) |
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

## 📍 جلسة sweep الـ design system (commits على main)
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
- `8b87d07` — **sub-step e:** whatsapp/OTP (أصلح deprecation `otp_input_row:84` background؛ منطق محفوظ: LTR-lock + focus-advance + timer الـ resend).
- `85c3d63` — **sub-step f:** oath (طوينا الـ hex المؤجّل لتوكنز؛ تدرّج `paper→creamSurface`، `panelR`، ظل `e3`؛ توكن `QeranRadii.xs` جديد للـ checkbox).
- `5df72f9` — **sub-step g:** upload-image (الكتلة كانت شبه مهاجَرة؛ بقي `CustomButton`→`QeranButton` بالشاشة الرئيسية).

**الحالة:** 0 ✅ · a ✅ · b ✅ · b2 ✅ · c ✅ · d ✅ · e ✅ · f ✅ · g ✅ — **هجرة `auth/` مكتملة بالكامل** 🏁
**الباقي:** لا شيء داخل auth. التالي = الخطّابة M3 + باقي الـ sweep.

---

## 🧩 الخطّابة — M3 (إعادة تصميم البطاقة + التوحيد)
**معمول (commits على main):**
- `e4a9a82` — **sub-step 1:** إصلاح parser الاشتراك flat → nested (`{planName, expiresAt}`).
- `44c0e80` — **sub-step 2:** `age` + `answers[]` على كرت العضو (data+domain+widget؛ سطر العمر مستقل «عندي {age} سنة»، الإجابات نص حرفي ≤3).
- `fe1721f` — **M3a:** إعادة تصميم الكرت — حذف tap/التاريخ/chevron، صف أزرار لكل قائمة (scaffold).
- `644929d` — **M3b:** موافقة/رفض عبر **شيت تأكيد** (approve / reject-with-reason)؛ هجرة `reject_reason_sheet` لـ `QeranTextField`؛ توكن `softFill` + variant `neutral` + `QeranSheetHandle`.
- `940d5bc` — تحويل الـ base URL للسيرفر الجديد (`qeranadmin-001-site1.rtempurl.com/api/`).
- `1c83cd9` — **M3c:** زر المراسلة يفتح المحادثة (lazy-open بالـ `userId` → الشاشة الموجودة عبر `MatchmakerConversation` رفيعة؛ host على مستوى القائمة)؛ استخراج `MatchmakerCardAnswersBlock`.

**الوثيقة الموحّدة (طارق) — 3 ميزات فُكّ حجبها** (أكّدت age+answers / subscription nested / notes؛ شيلناهم من جدول الباك إند):
- **مرآة الاهتمامات:** 4 endpoints، `MatchmakerUserPageDto`، read-only، `isLocked`، يعيد استخدام `MatchmakerCardAnswer`. أسقط تاب «الزوّار» (فيجما) — بلا باك إند → **3 تابات**.
- **الملاحظات:** `GET/PUT/DELETE …/note`، **assigned-only**، 2000 حرف.
- **الملف:** انظر القرارات (عرض معكوس + عرض-فقط).

**الخطة (الجاي):**
- **M3d — الملاحظات:** صارت **full-stack** (الباك إند جاهز، كانت UI-only).
- **M3e — عرض:** سلك تنقّل واحد للشاشة الموجودة + **حذف** action-bar الموافقة + إزالة سقالة `ProfileEntrySource.matchmaker`.
- **M3f — مرآة الاهتمامات:** 3 تابات، إعادة استخدام كروت تطبيق المستخدم read-only (callbacks = null) + كتلة الإجابات؛ **الأكبر**، يعتمد على M3e.
