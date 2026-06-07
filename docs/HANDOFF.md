# Qeran — Handoff (وين وصلنا)

> **الغرض:** الطبقة غير المستنتَجة من حالة المشروع — النية، القرارات، الخطوات الجاية، الـ gotchas، بنود الباك إند. حالة الكود نفسها (أي شاشة موحّدة/لأ) تُستنتَج من الكود + legacy-grep — لا تُكتب هنا (تبيت قديمة).
> اقرأه أول شي كل جلسة (أنا الويب + Claude Code). حدّثه نهاية كل مهمة.
> آخر تحديث: 7 يونيو 2026

---

## 🎯 النية / المهمة الحالية
**تطبيق الخطّابة مكتمل الميزات 🏁** — سلسلة M3 + **خطة الإغلاق (5 ميزات) كلها معمولة**. تفاصيل M3 بقسم «🧩 الخطّابة — M3»، والإغلاق بقسم «🧩 الخطّابة — الإغلاق (5 ميزات)». **الجاي** (post-close-out): QA تشغيلي كامل على حساب Moderator حقيقي (انظر «⚠️ أعلام التحقّق التشغيلي») + باقي sweep تطبيق المستخدم (onboarding/notifications/subscriptions-legacy/questionnaire + `share_with_matchmaker` dialog) + إعداد المنصّات (iOS Firebase/push، توقيع Android) + بناء الباقات/paywall + IAP. auth ✅ مكتملة.

**الدفع = IAP** (In-App Purchase) — محسوم؛ يحتاج تحقّق إيصال على الباك إند (طارق) وقت ربط ميزة الباقات/paywall.

## 🗺️ الخطوات الجاية (بالأولوية)
1. ~~**هجرة auth/ الكاملة**~~ ✅ **مكتملة** (0→g كلها معمولة — انظر «🔧 هجرة auth — التقدّم»). يبقى فقط: `share_with_matchmaker_button._confirmDialog` (مؤجّل — انظر Deferred).
2. ~~**الخطّابة — سلسلة M3 ⭐**~~ ✅ **مكتملة 🏁** (M3a→M3f-c — انظر «🧩 الخطّابة — M3»).
3. ~~**الخطّابة — خطة الإغلاق (5 ميزات)**~~ ✅ **مكتملة 🏁** (الإعدادات → الزميلات → فلتر الحالات → الاستكشاف → الإشعارات — انظر «🧩 الخطّابة — الإغلاق»).
4. **QA تشغيلي على حساب Moderator** — تشغيل التطبيق + المرور على الميزات الخمس + أعلام التحقّق (انظر «⚠️ أعلام التحقّق التشغيلي»). لا شيء منها يحجب.
5. **باقي الـ sweep (تطبيق المستخدم)** — onboarding، notifications، subscriptions (widgets legacy: `discount_code_field`/`pricing_segment`/`feature_row`/`plan_visual`…)، questionnaire widgets، settings (بسيط) + `share_with_matchmaker` dialog. شاشة شاشة (legacy-grep gate يخدم هذا).
6. **إعداد المنصّات:** iOS (Firebase/push) + توقيع Android (signing).
7. **الباقات/paywall + IAP:** ربط الدفع عبر **IAP** — تحقّق الإيصال على الباك إند (طارق).
8. **الاهتمامات (تطبيق المستخدم) — تاب التوافق:** تعديل شكلي بسيط حسب فيجما — لاحقاً.
9. **الإعدادات:** إكمال المتبقّي.

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
  - **الملف = عرض فقط (معمول M3e):** action-bar الموافقة/الرفض **داخل** الملف **محذوف** — كل الموافقة/الرفض على **الكرت** (M3b). يبقى زر تعديل-الإجابات. سقالة `ProfileEntrySource.matchmaker` الميتة **محذوفة**.
  - **request-photo → شيت المراجعة (M3e2):** بعد حذف action-bar الملف، قدرة «طلب صورة» انتقلت لشيت مراجعة الكرت (pending) — زرّ ghost **مشروط بعدم وجود صورة** (`hasProfileImage == false`).
  - **مرآة الاهتمامات — ميزة منفصلة read-only (M3f):** `lib/features/matchmaker/interests/` مستقلة. **إعادة استخدام building blocks** (`LikeBlurredImage`/`MatchCardScaffold`/`MatchmakerCardAnswersBlock`) **لا** كروت تطبيق المستخدم الكاملة — كرت الماتش يعرض CTAs شبحية معطّلة (مش مخفية) فما ينفع read-only. **3 تابات** (لا «زوّار»). `isLocked` يُخفي الطرف الآخر (صورة مغبّشة + إخفاء الاسم/الإجابات) **بلا أي CTA اشتراك** (الخطّابة ليست المشتري). الـ countdown **مكتوم**. نقر الكرت → الملف (`otherPartyId`؛ يعمل لأي مستخدم — `…/profile` **ليس** assigned-only، فقط الملاحظات assigned-only). الأرشيف = قسم «الأرشيف» inline تحت النشِط.
  - **توكنز/widgets جديدة بالـ DS (هذه السلسلة):** `softFill` (`#1A431C33`، ~10% واين، تعبئة chip ناعمة) + `QeranButtonVariant.neutral` (الـ variants صارت **7 مش 6** — `DESIGN.md` stale بهالنقطة) + `QeranSheetHandle` مشترك + `MatchmakerCardAnswersBlock` (أُعيد استخدامه بـ M3f) + `QeranTextField` يبدّل تلقائياً لـ `controlR` على `maxLines>1` (يصلح pill الشيت متعدد الأسطر).
  - **قاعدة أزرار الكرت:** **زر مملوء واحد** `primaryWine` لكل قائمة (pending = موافقة، الباقي = مراسلة)، والباقي chips `neutral`؛ داخل `Wrap` فالـ labels ما تنقص أبداً.
- **— الخطّابة (قرارات الإغلاق، غير مستنتَجة):**
  - **فلاتر الاستكشاف + الحالات = شيتات خطّابة موازية:** نعيد استخدام **sub-widgets فلتر discovery** (`FilterExpandableMulti/Select`, `FilterTextField`) فقط — **بلا لمس** discovery (الـ `FilterQuestionRenderer` مربوط بـ `DiscoveryFilterCubit` فاستُنسخ renderer خطّابة موازٍ + cubit/state موازيان). `MatchmakerExploreFilterCubit` يحاكي `DiscoveryFilterCubit` (ما يُعاد استخدامه).
  - **فلاتر النطاق (range) مُسقَطة بالاستكشاف:** select/radio/checkbox/text + `search` + `gender` فقط (height/weight/date تُسقَط على التحميل، زي ما discovery يُسقط غير الصالح). تعليق توسعة `RangeFrom/RangeTo` باقٍ بـ `buildExploreQuery` إن أكّد الباك إند لاحقاً.
  - **فلتر الحالات = client-side:** الـ endpoint يقبل `page/pageSize` فقط (لا `?status=`/`?search=`)، فالفلترة فوق العناصر **المُحمَّلة**؛ `pageSize` رُفع لـ 100 (الحالات قليلة لكل خطّابة). محدودية «يفلتر المُحمَّل فقط» موثّقة بالكود.
  - **الزميلات = استنساخ ستاك محادثات المستخدم:** الكيان `MatchmakerConversation` عام فأُعيد استخدامه؛ «محادثة جديدة» = **FAB ذهبي** على سيغمنت الزميلات يفتح دليل الزملاء. parsing **دفاعي** (`name ?? fullName`, شكل مسطّح) — **CODE WINS** على شكل الوثيقة المتداخل القديم.
  - **الإشعارات — unread محلي:** الباك إند بلا `isRead`/mark-as-read (count = الإجمالي)، فالـ badge heuristic محلي: `max(0, currentTotal − lastSeenCount)` مخزّن بـ prefs (`matchmakerNotifLastSeenCount`). الـ badge cubit **singleton** (كل `MatchmakerAppBar` + الصندوق يشتركون نفس النسخة). **لا نقطة unread لكل صف** (لا حالة قراءة من الباك إند — نعرض فقط ما يدعمه). الصندوق يبني tile موازٍ DS-pure (ما لمسنا `notification_tile` القديم legacy).
  - **baseUrl صار `https`** — مقصود (commit مع F3).
  - **الدفع = IAP** — محسوم؛ تحقّق إيصال على الباك إند (طارق) عند بناء paywall.

---

## ⚠️ Gotchas (تنبيهات)
- **رسائل الـ commit بتكذب:** commits قديمة تدّعي توحيد auth/onboarding — لسا legacy. تأكّد من الكود دايماً.
- الدين التقني على جهة المستخدم؛ الخطّابة ~95% موحّدة أصلاً.
- `MATCHMAKER_DIAGNOSTIC.md` القديم stale — أشياء قال "ناقصة" صارت معمولة. ثق بالكود.
- **Profile hub — تاب العرض ما بيتحدّث بعد الحفظ:** `MyProfileCubit` لسا داخل `ProfileSelfView` (مش مرفوع فوق الـ `TabBarView` بالـ hub)، فالتابّان لهما instances منفصلة. الإصلاح المقترح: ارفع `MyProfileCubit` فوق الـ hub ليتشارك التابّان نفس الـ cubit ويعيد التحميل بعد الحفظ. (متحقَّق منه هذه الجلسة — لسا غير معمول.)
- **reset_pass متحقَّق:** بعد تبنّي العين المدمجة (sub-step c/d) الشاشة تُصرّف صح والعين تبدّل — لا إجراء مطلوب.
- **`'auth.country_search_hint'` كنص خام** في `country_code_picker` (مش عبر `LocaleKeys`) — موجود مسبقاً؛ تحقّق إنه يُحَل AR+EN.

---

## ⚠️ أعلام التحقّق التشغيلي (اختبارها على حساب Moderator حي — لا شيء منها يحجب)
- **تاب الاستكشاف مركّب فعلاً بالـ bottom-nav** (مش الـ placeholder القديم) — الـ shell يركّب `MatchmakerExploreTab` (متحقَّق بالكود؛ يبقى تأكيد بصري).
- **أشكال صفوف محادثات/دليل الزميلات** (مسطّح `fullName` vs `name`؛ array vs paged) — parsers دفاعية تغطّي الاثنين، تأكيد فقط.
- **أشكال قائمة/عدّاد الإشعارات** (array vs paged؛ `{count}` vs int خام) + **مفاتيح deep-link** بالـ `data` (JSON string) تطابق ما يتوقّعه `MatchmakerNotificationRouter` (type/conversationId/action/audience).
- **endpoint الملاحظات** لسا يفشل على السيرفر الجديد (يحتاج deploy من طارق) — M3d.
- **روابط «تواصل معنا» placeholders** (`https://qeran.com`, `instagram.com/qeran`…) — تحتاج حسابات Qeran الحقيقية من product (نسخ-للحافظة يعمل؛ فتح الرابط يحتاج `url_launcher` لاحقاً).
- **deep-link «الحالات» من الصندوق ما يقفز لتاب الحالات** (shell scope غير مكشوف للـ route المدفوع) — بسيط؛ مسار FCM-tap بالـ shell يملك deep-links اختيار-التاب.
- **خيوط الزميلات realtime** تحتاج حسابَي Moderator حيّين للتحقّق.

---

## ⏸️ مؤجّل (Deferred)
- **ملفّا اختبار likes قديمان** (`match_card_stage0_test`, `likes_cubit_test`) متأخران عن refactor `32ba51d` (حُذف `PhotoExchangeActionRow`، تغيّرت توقيعات الـ cubit/MatchCard). **الإنتاج نظيف** (`flutter analyze lib` = 0 errors) — اختبارات فقط، تحتاج تحديث/حذف.
- **`share_with_matchmaker_button`:** الـ `_confirmDialog` ملف مختلط نظامين (الزر الرئيسي `QeranButton` بس الـ dialog لسا Material + `AppColors`) — يحتاج هجرة كاملة، مش إصلاح سطر.

---

## 📨 معلّق على طارق (Backend)
| البند | الحالة |
|-------|--------|
| **الخطّابة — endpoint الملاحظات يفشل على السيرفر الجديد** | ⚠️ **محجوب** — يحتاج deploy/إصلاح (متحقَّق عبر Swagger)؛ كود M3d جاهز وينتظر |
| **الخطّابة — نص `status` بالأرشيف:** مترجَم حسب `Accept-Language` ولا عربي فقط؟ | معلّق — يحدّد هل نعرض نص الباك إند أم label الـ `reason` عندنا (M3f-c يعرض النص الخام حالياً) |
| `GET /users/subscription-plans` منشور؟ + فلتر `?planId=` شغّال؟ | معلّق — يحجب شريط تابات الباقات + paywall/IAP |
| **الخطّابة — تحقّق إيصال IAP** على الباك إند | معلّق — مطلوب وقت بناء paywall (الدفع = IAP محسوم) |
| **الخطّابة — روابط «تواصل معنا» الحقيقية** (product) | معلّق — حالياً placeholders |
| **الخطّابة — شكل رد** `GET …/{id}/chat`: `data:123` ولا `{conversationId}`؟ | معلّق — **non-blocking** (parser دفاعي يغطّي الاثنين) |
| **الخطّابة — أشكال colleagues/notifications** (مسطّح vs متداخل، array vs paged) | معلّق — **non-blocking** (parsers دفاعية تغطّي) |
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

## 🧩 الخطّابة — M3 (إعادة تصميم البطاقة + التوحيد) — ✅ مكتملة 🏁
**الحالة:** السلسلة **كاملة** — إعادة تصميم الكرت + موافقة/رفض + مراسلة + ملاحظات + عرض + مرآة الاهتمامات، كلها معمولة ومـcommitted.

**معمول (commits على main):**
- `e4a9a82` — **sub-step 1:** إصلاح parser الاشتراك flat → nested (`{planName, expiresAt}`).
- `44c0e80` — **sub-step 2:** `age` + `answers[]` على كرت العضو (data+domain+widget؛ سطر العمر مستقل «عندي {age} سنة»، الإجابات نص حرفي ≤3).
- `fe1721f` — **M3a:** إعادة تصميم الكرت — حذف tap/التاريخ/chevron، صف أزرار لكل قائمة (scaffold).
- `644929d` — **M3b:** موافقة/رفض عبر **شيت تأكيد** (approve / reject-with-reason)؛ هجرة `reject_reason_sheet` لـ `QeranTextField`؛ توكن `softFill` + variant `neutral` + `QeranSheetHandle`.
- `940d5bc` — تحويل الـ base URL للسيرفر الجديد (`qeranadmin-001-site1.rtempurl.com/api/`).
- `1c83cd9` — **M3c:** زر المراسلة يفتح المحادثة (lazy-open بالـ `userId` → الشاشة الموجودة عبر `MatchmakerConversation` رفيعة؛ host على مستوى القائمة)؛ استخراج `MatchmakerCardAnswersBlock`.
- `835403e` — **M3d:** الملاحظات full-stack (`GET/PUT/DELETE …/note`، assigned-only، عدّاد 2000 حرف، تأكيد-قبل-حذف، 4 مسارات أخطاء)؛ أضفنا `put()` للـ ApiConsumer + `QeranTextField` auto `controlR`.
- `4d8a469` — **M3e:** عرض → الملف (سلك تنقّل واحد) + الملف **عرض-فقط** (حذف action-bar) + حذف سقالة `ProfileEntrySource.matchmaker`.
- `17a8c82` — **M3e2:** إعادة «طلب صورة» لشيت مراجعة الكرت (مشروط `hasProfileImage == false`).
- `e1de2fb` — **M3f-a:** طبقة data/domain لمرآة الاهتمامات (4 endpoints، 8 entities، 6 models، datasource بـ `_page` helper، repo، 3 usecases، DI).
- `0440908` — **M3f-b:** cubit/state + شاشة + 3 تابات + route + سلك «الإهتمامات» (تاب حي واحد).
- `68cfedc` — **M3f-c:** الكروت read-only الحقيقية (like/match/archive) + قسم «الأرشيف» inline + نقر→الملف + تصحيح أسماء حقول M3f-a لوثيقة طارق (archive: `type`+`reason`، إسقاط age الوهمي؛ like: `profileId`؛ match: `formalRequest`).

**ملاحظات تنفيذية (للمتابعة):**
- مرآة الاهتمامات: نص الأرشيف `status` يُعرض **خام من الباك إند**؛ إن كان عربي-فقط فالإنجليزية ستعرضه عربياً — قرار معلّق على طارق (انظر الجدول). الـ `reason` label مترجَم عندنا كاحتياطي.
- إعادة استخدام `LikeBlurredImage` (من ميزة likes) يحمل `AppColors` legacy **داخلياً** — موجود مسبقاً، ما لمسناه (legacy-grep على ملفاتنا = صفر).

---

## 🧩 الخطّابة — الإغلاق (5 ميزات) — ✅ مكتملة 🏁
**الحالة:** خطة الإغلاق كاملة بالترتيب المحسوم — الإعدادات → الزميلات → فلتر الحالات → الاستكشاف → الإشعارات. القرارات بقسم «القرارات الثابتة → الخطّابة (قرارات الإغلاق)»؛ أعلام التشغيل بقسم «أعلام التحقّق التشغيلي».

**معمول (commits على main):**
- **الميزة 1 — الإعدادات (الحساب `matchmaker/me`):** `395213e` (S1a · data/domain) · `aca3d4d` (S1b · cubit + شاشة الإعدادات) · `c979d1a` (S1c · شيت تعديل الاسم + شيت تغيير كلمة المرور + «تواصل معنا»). يغطّي: عرض الحساب، تعديل الاسم، رفع الصورة (multipart `Images`)، تعطيل الحساب، تغيير كلمة المرور (`/api/auth/change-password`)، روابط التواصل (placeholders).
- **الميزة 2 — الزميلات:** `2fb2587` (data/domain — `MatchmakerColleague` + إعادة استخدام كيان المحادثة، 3 usecases) · `ee93c82` (قائمة محادثات الزميلات + شاشة الدليل + open-chat + FAB ذهبي على السيغمنت).
- **الميزة 3 — فلتر الحالات (client-side status + name):** `2f494d3` (كيان الفلتر + cubit رفيع + شيت بإعادة استخدام sub-widgets discovery + شريط فلتر بنقطة نشاط؛ `pageSize` 100؛ تضمين تحويل baseUrl→https).
- **الميزة 4 — الاستكشاف:** `bb45e69` (data/domain + `buildExploreQuery` المنقول) · `a4f8537` (شيت الفلتر الموازي — cubit/state/renderer) · `14955f1` (الشاشة — بحث debounced + سيغمنت الجنس + أيقونة فلتر + قائمة الكروت؛ نقر→الملف).
- **الميزة 5 — الإشعارات:** `f05a2b7` (صندوق inbox مرقّم + model حقيقي يفكّ `data` JSON-string + badge unread محلي singleton + tile DS موازٍ + سلك الجرس بكل التابات؛ ثابتا endpoint `notifications`/`notifications/count`).

**ملاحظات تنفيذية (للمتابعة):**
- كل الميزات: gates خضراء (`flutter analyze lib` = 0 errors عدا lint `notification_tile:26` القديم؛ legacy-grep صفر على ملفاتنا؛ ملفات <200).
- الـ DS الجديد بهالإغلاق: `MatchmakerExploreFilterRenderer` (renderer خطّابة موازٍ)، `MatchmakerNotificationTile` (tile DS موازٍ)، badge cubit singleton.
