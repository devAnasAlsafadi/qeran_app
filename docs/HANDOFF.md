# Qeran — Handoff (وين وصلنا)

> **الغرض:** الطبقة غير المستنتَجة من حالة المشروع — النية، القرارات الثابتة، الخطوات الجاية، الـ gotchas، بنود الباك إند، بيانات الحسابات/الاعتمادات. حالة الكود نفسها تُستنتَج من الكود + legacy-grep.
> اقرأه أول شي كل جلسة. حدّثه نهاية كل مهمة.
> **آخر تحديث: 17 يوليو 2026** — بعد **جلسة الدفع (شاشة «اشتراكي» + شراء) + إصلاح الوقت UTC + إصلاح state-race بالديسكفري** (commits `40d1089..d8fb097`، **مدفوعة**). التحديث السابق: اكتمال إعادة تصميم الخطّابة + إعداد المتاجر (11 يوليو).

---

## 🎯 الحالة الحالية — الصورة الكبيرة

**تطبيق الخطّابة صار مكتملاً بصرياً 🏁** — **كل 11 شاشة أساسية + كل 3 شيتات** أُعيد تصميمها وشُحنت. **مرحلة الصقل البصري (Design Polish) انتهت** (onboarding + auth + gender + Interests/Match-success + كل شاشات الخطّابة).

- **Google Play:** العروض **حيّة end-to-end** (3 اشتراكات + 30 عرضاً Active؛ شراء حقيقي مُختبَر على الجهاز).
- **Apple App Store:** الـ metadata + إعدادات الـ 30 عرضاً **مكتملة**؛ Custom Codes + build معلّقان على Mac.
- **وثيقتا طارق جاهزتان للإرسال** (backend tasks + offers reference).

**الجاي = دفع + إرسال + جولة تصميم ثانية (round-2)، لا صقل بصري متبقٍّ لشاشات الخطّابة الأساسية.**

---

## 🆕 جلسة الدفع + إصلاح الديسكفري (17 يوليو — commits `40d1089..d8fb097`، مدفوعة)

**ما شُحن (8 كوميتات، بترتيب التبعية):**
- **`40d1089` fix(core):** تحليل طوابع الوقت من الباك إند كـ **UTC**. الباك إند يرسلها UTC **بلا لاحقة `Z`** → Dart يقرأها local → الاشتراك النشط يُقرأ «منتهياً» (~3 ساعات مبكّراً، إزاحة UTC+2/+3). ملف جديد `lib/core/utils/server_datetime.dart` فيه `parseServerDateTime` (حارس `hasTz`: يضيف `Z` فقط إن غابت — سليم **قبل وبعد** ما يرسل طارق `Z` صحيحاً). مُرِّرت **8 مواقع** تحليل (json_parsers لـ 6 features + موديل likes + الاشتراكات). `isCurrentlyActive` يقارن UTC. `hasReliableExpiry`: فشل التحليل → كرت خطأ (لا «منتهٍ»). **مُستثنى:** birthdate/الاستبيان (تواريخ date-only يدخلها المستخدم — تحويلها UTC يفسدها).
- **`8c57bef` feat(subscriptions):** شاشة «اشتراكي» (6 حالات: نشط بـ donut + صفوف الاستحقاقات · ينتهي ≤7 أيام · منتهٍ · مجاني · تحميل · خطأ/expiry-مجهول) + كرت الترقية بالبروفايل + مفاتيح ترجمة + إصلاح دَين التوطين (13 نصاً مضمّناً → LocaleKeys).
- **`f104f9b` feat(subscriptions):** شاشتا نجاح/فشل الشراء + التوجيه. شاشة الفشل تعرض **السبب المحدّد** (بطاقة مرفوضة / المتجر غير متاح / مشترك أصلاً) و«إعادة المحاولة» تُعيد إطلاق الشراء فعلاً (تحفظ الباقة + الخصم)، «رجوع» يعود للباقات.
- **`4a6425e` fix(subscriptions):** العملة SAR→**$** · الباقة المجانية «**مجاني**» (بلا عملة) · توطين كروت الباقات · `withOpacity`→`withValues`.
- **`7624df3` fix(subscriptions):** شراء base-plan option عند غياب العرض.
- **`7688287` fix(ui):** clearance للـ bottom-nav (آخر العناصر كتسجيل الخروج كانت مخفية خلف الشريط).
- **`d9c8c88` fix(discovery):** **الكبيرة.** الفيد يقف عند ~10–20 ملفاً. الجذر = **state race**: `like()` التقط snapshot قديماً للملفات قبل await (len=10)، الـ prefetch أضاف الصفحة 2 أثناء نافذة الـ ~1.5s (heart-burst)، ثم `_advance` أطلق الـ snapshot القديم → داس الصفحة 2 (len رجع 20→10) **و** أعاد `isPrefetching` true → **loader دائم**. الإصلاح: كل emit بعد await **يقرأ الحالة الحيّة** ويلمس حقله فقط (index للتقدّم، error للفشل) → profiles/isPrefetching ينجوان. + العرض يظهر loader (لا EmptyView) طالما `hasMore` + `ensurePrefetch()` أمان + العتبة 3→6 + مسار DROPPED يصفّر العلم. (`pass()` لم يكن racy — متزامن.)
- **`d8fb097` chore(android):** مسار الحزمة + إعداد locale الـ JVM.

**✅ تحقّق على الجهاز:**
- الاشتراك يُقرأ **نشطاً** بعد إصلاح الوقت (اللوج أظهر انتهاء 2026-08-15، بعيد شهراً — لا artifact الـ 5-دقائق Sandbox المُقروء غلطاً كمنتهٍ).
- الديسكفري: التمرير السريع يرفع len 10→20→30 بلا رجوع، لا loader عالق.

**⛔ WIP مؤجَّل (غير مكوميت في working tree — لا تُضِعه):**
- `splash_screen.dart`: إعادة تصميم wine full-bleed + إزالة diags، لكن فيه **مشكلة JSON غير محلولة** (أنس وقف في المنتصف، يكمّلها لاحقاً).
- likes round-2 (4 ملفات): `likes_segmented_tabs.dart` · `match_card.dart` · `match_card_avatar.dart` · `qeran_strokes.dart` (توكن جديد) — صقل بصري لخصوصية الصور/التابات، **غير مُراجَع بصرياً**.
- **مستثنى أيضاً:** `data.json` · `docs/_design/` · `web/` · حذف `_archive/*.md` (لا تُكوميت).

**حالة ميزة الاشتراك:** ~90% مكتملة + شغّالة، **لا stubs/TODOs**. المتبقّي = gaps B/C (تأكيد باك إند، بجدول طارق) + hero النجاح ثابت (cosmetic follow-up).

> **ملاحظة:** شاشة اهتمامات الخطّابة (redesign) مكتملة ومدفوعة أصلاً — `e49455b feat(matchmaker): redesign user-interests screen onto the design system`. **لا تُعالَج ثانيةً.**

---

## 🔴 معلّقات فورية (تُحَلّ أول الجلسة الجاية — خطر/حاجب)

1. **✅ حُلّ:** كل كوميتات هذه الجلسة (`40d1089..d8fb097`) وما قبلها **مدفوعة** لـ `origin/main` — `git log origin/main..HEAD` فارغ. (كان التنبيه «12+ غير مدفوعة».)
2. **HANDOFF.md كان قديماً** حتى هذا التحديث (كان يقول «الجاي: صقل شاشات الخطّابة») — حُدِّث الآن.
3. **وثيقتا طارق جاهزتان لكن لم تُرسَلا:**
   - `docs/_plan_drafts/TARIQ_backend_tasks.md` — ⚠️ **يحتاج إصلاح سطر مكسور في قسم 2.2 قبل الإرسال:** رأس `GET /api/matchmaker/me` مشوَّه (ناقص `**` البادئة + backtick) — نسّقه مثل باقي رؤوس الـ endpoints: `` **`GET /api/matchmaker/me`** ``.
   - `QERAN_OFFERS_TARIQ.md` — مرجع الـ 30 عرضاً (أنس يملكه محلياً من Web chat؛ **ليس في الريبو** بعد).
4. **جولة round-2 (3 شاشات جديدة للتصميم):** Matchmaker User Interests + User Notifications + Matchmaker Notifications. **الجرد READ-ONLY جاهز** في `docs/_plan_drafts/round2_inventory.md`. **التصميم الفعلي غير مبدوء.**
5. **تعديل Dashboard بسيط معلّق:** إضافة اسم الخطّابة فوق تحية السلام («مرحباً هدى» / «الخطّابة هدى»). الاسم متوفّر عبر `UserSessionCubit.currentUser?.name`. يُعمَل بعد نزول تصاميم round-2.
6. **gender re-skin لسا غير مكوميت** — محجوب على PNGs شفّافة (Gemini يبيّض «الشفّاف» كـ checkerboard مطبوخ — يحتاج remove.bg أو Photopea).
7. **ملفات Interests round-2 لسا غير مكوميتة** (`match_card.dart`, `match_card_avatar.dart`, `qeran_strokes.dart`) — أنس أجّل المراجعة لجلسة لاحقة.
8. **iOS Custom Codes محجوبة** على توفّر Mac + App Review + سيرفر توقيع JWS من طارق.

---

## ▶️ الخطوة الجاية

**إعادة تصميم الـ 11 شاشة + 3 شيتات = مكتملة.** أولويات الجلسة الجاية بالترتيب:
1. **ادفع كوميتات الجلسة لـ `origin/main`** (حماية).
2. **أرسل وثيقتي طارق** (بعد إصلاح سطر 2.2).
3. **round-2:** brief لـ Claude Design لـ 3 شاشات (Interests + إشعارات المستخدم + إشعارات الخطّابة) — الجرد جاهز `round2_inventory.md` → ثم تنفيذ Claude Code بمنهجية plan-first المعتادة.
4. **تعديل Dashboard:** الاسم فوق تحية السلام.

**مراحل لاحقة:**
- **لوحة الإحالة (affiliate) المالية للخطّابة** في الإعدادات — **محجوبة على طارق** (بناء الـ endpoints أولاً).
- **تفعيل iOS:** Mac + Xcode + build + App Review + توليد Custom Codes + سيرفر توقيع JWS من طارق.
- **كوميت gender re-skin** (محجوب على PNGs شفّافة).
- **مراجعة ملفات Interests round-2** (أنس أجّلها).

---

## 🗂️ ما شُحن هذه الجلسة

### إعادة تصميم الخطّابة الكاملة — 11 شاشة + 3 شيتات

عبر الـ pipeline: **Claude Design** (briefs نصّية، بلا screenshots) → `docs/_design/handoffs/*.md` + `Qeran_Matchmaker_Home.html` → **Claude Code** (plan-first) → مراجعة بصرية RTL+LTR بين كل شاشة → كوميت ذرّي. **كل طبقات البيانات محفوظة 100% — إعادة بناء UI فقط.**

الكوميتات (الأحدث أولاً، كلها على `main`، **غير مدفوعة**):
- `c99b679` — **feat(settings):** الإعدادات + kit مشترك للدورين (11).
- `e1d8d5c` — polish: أزرار footer الشيت 50/50 (تلائم العربي).
- `a6abcf0` — feat: شيت المشاركة (10).
- `c09cebc` — feat: shell الشيت المشترك + شيتا فلتر الحالات/الاستكشاف (08/09).
- `0018136` — fix(explore+loader): loader لكل كرت + توحيد spinner التطبيق.
- `2800c4d` — fix(inbox): لا إعادة جلب القائمة عند فتح خيط.
- `5811237` — polish(explore): كروت المرشّحين + إصلاح الأفاتار المكسور.
- `4cba02e` — polish(cases): قائمة + تفاصيل الحالات.
- `658cfef` — fix(matchmaker): وقت نسبي + pill unread على الصندوق.
- `10e3635` — feat(chat): خيط المحادثة المشترك.
- `965b2fc` — feat(matchmaker): قائمة Users.
- `fdd356d` — feat(matchmaker): Dashboard.
- **مدفوعة أصلاً:** `51cd063` (SafeEmit) · `d9ff232` (حارس emit في `PaginatedListCubitMixin`) · `bcc1146` (مطابقة باقة RevenueCat).

**تفاصيل الشاشات:**
1. **Dashboard** (`fdd356d`) — monogram تحية + سلام + الاسم (من `UserSessionCubit`) + التاريخ · كروت «تحتاج انتباهك» hero · شبكة 2×2 · حالة صفر هادئة. `intl` مُهيّأ عند البدء لتواريخ عربية.
2. **Users** (3 sub-tabs، `965b2fc`) — تابات wine-pill منزلقة · monograms 52px · fact chips مقتطعة · gold plan chips للمشتركين · 3 مجموعات أكشن (pending/unsubscribed/subscribed).
3. **Chat thread** (⚠️ مشترك مع تطبيق المستخدم، `10e3635`) — subtitle محايد «نشط الآن» مربوط بالاتصال الحيّ · فقاعات واين/paper بحدود · دائرة ذهبية + طائرة واين للإرسال · كرت الملف-المشارَك cream+gold-40 مع chip نتيجة التوافق · read-receipt **مُبقى ومُعاد تنسيقه**.
4. **Conversations inbox** (2 tabs، `658cfef`) — مستخدمون/زملاء عبر wine-pill · وقت نسبي مقروء («منذ X دقيقة/ساعة/يوم») · badge ذهبي unread على الحافة اللاحقة · `refresh()` الشامل استُبدل بـ `markConversationRead` in-place.
5. **Cases list + Detail** — **قطب إعادة التصميم.** widget جديد `QeranStepper` + helper `buildCaseTimeline` (يُسقط الحقلين الحقيقيين — `stage` + `formalRequest.status` — على 5 عُقد كانونية) + **10 اختبارات وحدة**. chips حالة ملوّنة (gold/wine/soft-fill/danger). الـ timeline يحترم الحالات المنتهية.
6. **Explore** (`0018136` وغيره) — إشارة الملكية أعلى-end (ذهبي «مستخدمي» / soft-fill اسم-المالك للآخر) · **إصلاح الأفاتار المكسور المتكرّر** عند `MatchmakerUserAvatar` المشترك (errorListener + إخلاء الـ cache — قتل كتل الأفاتار الخضراء عبر Explore + Cases + Inbox دفعة واحدة) · مجموعات أكشن شرطية (mine vs other).
7–9. **الشيتات الثلاثة** (`c09cebc` + `a6abcf0`) — **shell جديد** `QeranBottomSheet` + `QeranBottomSheetScaffold` + `QeranRangeSlider`. فلتر الحالات → **stage اختيار-واحد** من نفس مصدر الـ timeline (`matchmaker_case_labels.dart` — صفر تباعد). فلتر الاستكشاف **backend-driven بالكامل من `/filters`** (لا hardcode). شيت المشاركة: كرت سياق المرشّح + بحث client-side + حالة نجاح داخل الشيت.
10–11. **Settings** (رئيسية + فرعية، `c99b679`) — **kit مشترك** (`SettingsProfileHero` + `SettingsRow` + `SettingsLogoutCard`)، الدوران يركّبانه بمحتوى شرطي. اللغة صارت **`QeranBottomSheet` حيّ** (الصفحة + الـ route القديمان متقاعدان). شارة «موثّق» + «الملف الشخصي مكتمل» **مبوَّبتان على أعلام اختيارية** — مخفيّتان حتى وجود حقل الباك إند، جاهزتان للظهور التلقائي. صفوف destructive بلون danger.

### إضافات نظام التصميم (كانونية — تُستخدَم مستقبلاً)

- **`QeranMonogram`** (core DS، `+ borderRadius` اختياري لمربّع مدوّر) — أفاتار الهوية واين+ذهبي.
- **`QeranStepper`** — عمودي، data-driven، حالات done/current/future × نبرات normal/success/ended + هالة gold-12.
- **`QeranBottomSheet` shell** — `showQeranBottomSheet()` + `QeranBottomSheetScaffold` (دوم + `e3` + scrim + handle + إغلاق دائري + footer مثبّت).
- **`QeranRangeSlider`** — track واين08 + مقطع نشط ذهبي + إبهام ذهبي.
- **widgets الخطّابة:** `MatchmakerFactChips` (chips كريمية مقتطعة + عمر) · `MatchmakerCardActionBar` (+ `MatchmakerPrimaryAction`/`SecondaryAction`/`IconAction`) · `MatchmakerUserAvatar.monogramName` (fallback opt-in) · `SettingsProfileHero`/`Row`/`LogoutCard`.
- **توكنز جديدة:** `QeranColors.gold18` (`0x2EE4C094` — رُتبة «18» الناقصة من ramp الذهبي 08/12/18/20) · **danger ramp** (`danger08/12/40` — التسوية التي طلبتها الـ foundations) · `QeranChipVariant.plan` (gold-12/gold-40/gold-deep).
- **متقاعد:** كل `CircularProgressIndicator` خام في lib (صفر متبقٍّ — مؤكَّد grep؛ `QeranLoader` هو الـ spinner الوحيد، واين+ذهبي، حتى بشاشة الدخول) · صفحة+route `settings_language_screen` القديمة (استُبدلت بشيت اللغة الحيّ) · `MatchmakerExploreActionRow` (استُبدل بـ `MatchmakerCardActionBar` المشترك).

### 🛡️ مسح أمان الحالة (state-safety)

بعد ظهور crash الـ emit-after-close على **شاشة ثانية** (غير شاشة الإشعارات المُصلَحة سابقاً)، طُبِّق helper مشترك **`SafeEmit`** (`lib/core/state/safe_emit.dart` — يغلّف `emit()` → no-op بعد `close()`) على كل الـ cubits التي تـ`emit` بعد `await`. `PaginatedListCubitMixin` كان مُغطّى من الإصلاح الأسبق؛ المسح وحّد الباقي تحت نمط واحد. **الـ Bloc** خارج التغطية — احرس `if (emit.isDone) return;`.

### 🐞 أخطاء جانبية اكتُشفت وأُصلحت أثناء المراجعة البصرية

- **spinner أيقونة الرسالة يدور على كل كرت بنفس المالك:** مفتاح التحميل كان `matchmakerId` (غير فريد لمّا كل الكروت لنفس المالك) → صار `userId` (فريد لكل كرت). الكرت المضغوط فقط يدور.
- **إعادة تحميل الصندوق عند فتح خيط:** `onTap` الكرت كان يستدعي `refresh()` (يجلب كل الصندوق) → استُبدل بـ `cubit.markConversationRead(id)` (تحديث in-place، بلا re-fetch، unread يُمسح للصف فقط).
- **اقتطاع زر footer الشيت («مسح ع...»):** `Row([ghost flex:1, primary flex:2])` كان يعطي الأساسي مساحة زائدة → 50/50 في الشيتات الثلاثة؛ يلائم كل الـ labels AR+EN.
- **الأفاتار المكسور (كتل بكسل خضراء):** الصورة الفاشلة كانت **JPEG مقطوعاً لكن قابل للفك** — الـ decode نجح على بايتات تالفة فما اشتغل الـ errorWidget. أُصلح عند `MatchmakerUserAvatar` المشترك بـ `errorListener` يُخلي إدخال cache الـ `CachedNetworkImage` فيُعيد التنزيل. **لأن الإصلاح في atom الأفاتار الوحيد المشترك، اختفت الكتل الخضراء من Explore + Cases + Inbox بكوميت واحد.**
- **وقت نسبي مكسور «Xي» بالصندوق:** الـ formatter القديم كان يلصق عدد الأيام بحرف لاحقة واحد → أُعيدت كتابته بمفاتيح localized («منذ X دقيقة/ساعة» / «أمس» / «منذ X يوم» / تاريخ قصير fallback). القيم غابت لحظياً عن ar/en.json (ظهرت كأسماء مفاتيح خام) — السبب: طريقة الـ filtered-staging تتخطّى المفاتيح الجديدة بصمت؛ أُضيفت صح.
- **توحيد الـ loader:** أي `CircularProgressIndicator` خام → `QeranLoader` (واين+ذهبي). loaders الأزرار المملوءة **تبقى أحادية اللون** عمداً (تباين على تعبئة gold/wine — القوس الثنائي يخفي قوساً على التعبئة). مؤكَّد grep: صفر خام متبقٍّ.

---

## 💳 IAP / Paywall / RevenueCat — إعداد المتجر الكامل

**الدفع يعمل end-to-end على الجهاز 🏁** — شراء حقيقي يكتمل ويرجّع entitlement `premium`. الجذر كان مطابقة الباقة (`"<productId>:<basePlanId>"` → `split(':').first`، `bcc1146`).

### Google Play (Android) — حيّ end-to-end
- **3 اشتراكات منشورة:** `qeran_basic_monthly` ($34.99) · `qeran_vip_monthly` ($49.99) · `qeran_vip_3month` ($119.99).
- **30 عرضاً ACTIVE** (10 لكل باقة): `basicmonthly-{5,10,15,20,25,30,40,50,70,90}` · `vipmonthly-{نفسها}` · `vip3month-{نفسها}`.
- شراء حقيقي مُختبَر بنجاح على الجهاز (SM A325F عبر Internal testing).
- `_findOption` في `purchase_repository_impl.dart` يقبل إمّا `offerId` مجرّد (`basicmonthly-90`) أو `basePlanId:offerId` كامل (`basic-monthly:basicmonthly-90`) — كلاهما يطابق.
- ⚠️ **`// TEMP` diagnostic log مؤقّت** في `purchase_repository_impl.dart:167-172` أبقاه أنس لتشخيص offer-id. **أرجعه قبل الإصدار.**

### Apple App Store (iOS) — 30 عرضاً مُعدّة، Custom Codes معلّقة على Mac
- 3 اشتراكات في مجموعة «Qeran Membership»، product IDs مطابقة لجوجل.
- **كل الـ metadata مكتملة:** Localization (عربي + إنجليزي) لكل اشتراك **وللمجموعة نفسها** — ⚠️ **هذا كان الـ unlock الحرج:** الاشتراكات تبقى «Missing Metadata» حتى تأخذ **المجموعة** localization خاصّاً بها (Apple لا يوضّح هذا؛ منشور مجتمعي كشفه ووفّر أياماً).
- التوفّر: كل 175 دولة.
- **Review Screenshots:** 3 لقطات paywall حُوِّلت من 720×1600 (لقطة أندرويد) إلى 1320×2868 (iPhone 6.9") عبر Python/Pillow على خلفية cream-canvas مموسطة (RGB، بلا alpha).
- **Review Notes** مكتوبة لكل اشتراك (إنجليزي).
- **Tax Category:** «Match to parent app» (الافتراض الصحيح — **لا تغيّره**).
- **كل الـ 30 عرضاً منشأة** بـ Reference Names مطابقة لجوجل («Basic 90%»، «VIP Monthly 15%»…).
- **نوع العرض: Offer Codes** (لا Promotional Offers) — Offer Codes تقبل New+Existing+Expired (أكواد أنس تروح لمستخدمين **جدد** — Promotional Offers تستثنيهم فتفشل بصمت)، وتشبه جوجل، وبلا توقيع JWS.
- كل عرض: Pay-as-you-go × شهر (أو **3 أشهر لباقة VIP 3Month** — gotcha: المدّة تطابق فترة الباقة لا «شهر») + eligibility New+Existing+Expired + «No, only this offer code» لسؤال العرض التمهيدي.
- **Product Codes** (المعرّف الذي يكتبه المستخدم) لا تُنشأ إلا **بعد App Review + رفع build** → محجوبة على Mac. العروض نفسها موجودة وجاهزة.

### الحسابات / الاعتمادات (credentials — احفظها)
- **Apple App Store Connect:** `info@qeran.ae` (Team `4C9GL7WLY7`)؛ Bundle `com.qeran.app` (Apple ID `6783272039`)؛ مجموعة «Qeran Membership» (`22177601`). Free Apps Agreement Active؛ Paid Apps + Sanctions review معلّقان (على العميل). API Key + IAP Key (Issuer `53b16cc6-51bb-42ae-b5e1-36807d3f7f5e`، Key `5L749KGK7C`).
- **Google Play Console:** `Qeran.Dev` (Personal، `4886994776950416347`)؛ الهوية مُتحقَّقة؛ حساب Merchant مُفعّل. **Google Cloud service account:** مشروع `qeran-iap`، `revenuecat-service-account@qeran-iap.iam.gserviceaccount.com` مربوط بالـ Play Console.
- **RevenueCat:** التطبيقان مربوطان (Android `app14550bb50c`، iOS `app659f7e615b`)، entitlement **`premium`** (مثبّت `revenuecat_config.dart:35`). مفاتيح Production مربوطة. مجاني حتى $2,500/شهر MTR.

---

## 📨 وثائق طارق (جاهزة للإرسال) + بنود الباك إند

### الوثيقتان
1. **`docs/_plan_drafts/TARIQ_backend_tasks.md`** (~11KB، مواصفة تقنية إنجليزية):
   - **قسم 1 (أكواد الخصم — تأكيد لا عمل جديد):** عقد `validate-code` كامل بأشكال JSON + اكتشاف تباين Swagger (v1 يوثّق GET قديماً فقط، لا الـ POST الذي يستدعيه التطبيق) + قواعد صيغة `offerId` الحرجة + تأكيد webhook RevenueCat→Play.
   - **قسم 2 (الإحالة — greenfield):** تسجيل يقبل `referralCode` · كشف كود الخطّابة على `/matchmaker/me` · `GET /api/affiliate/summary` (أعداد + عمولات + عملة) · `GET /api/affiliate/commissions` (تاريخ مرقّم) · سؤال عن `GET /api/Affiliate/stats` غير الموثّق · قرار نموذج العمولة.
   - ⚠️ **يحتاج إصلاح 2.2 قبل الإرسال:** سطر رأس `GET /api/matchmaker/me` مشوَّه (ناقص `**` + backtick) → `` **`GET /api/matchmaker/me`** ``.
2. **`QERAN_OFFERS_TARIQ.md`** (~7KB، مقدّمة عربية + مواصفة إنجليزية — حالياً في `/mnt/user-data/outputs/` من Web chat، **ليس في الريبو**):
   - اصطلاح التسمية (نفس `offerId` على المتجرين) · جدول 3×10 كامل (30 offerId + نِسَب + أسعار تقريبية + product IDs + base plan IDs) · عقد `POST /api/subscriptions/validate-code` بأمثلة · ملخص حالة المتجر · 4 تأكيدات مطلوبة من طارق. **أنس يقرّر إضافته للريبو أو إرساله standalone.**

### بنود مفتوحة (الجدول)
| البند | الحالة |
|-------|--------|
| 🔴 **طوابع الوقت بلاحقة `Z`** | أرجِع كل الطوابع UTC ISO 8601 **مع `Z`** (الإصلاح الجذري طويل الأمد). التطبيق يعمل الآن بأي حال عبر حارس `hasTz` بـ `server_datetime.dart`، **لكن الويب + العملاء المستقبليون يحتاجونه**. |
| 🟡 **تسعير متعدّد للباقة (gap B)** | هل أي باقة تعرض >1 تسعير (شهري/سنوي)؟ إن تسعير واحد لكل باقة → `selectedPricingId` غير المستهلَك بـ `plan_selection_widget` **dead code غير ضار**؛ إن متعدّد → الكروت تحتاج **toggle تسعير** (غير مبني). |
| 🟡 **مكان Restore-purchases (gap C)** | مراجعة Apple تتطلّب زر Restore **ظاهراً** — أكّد وصوله حيث تتوقّعه المراجعة (حالياً فقط بشاشة تفاصيل «اشتراكي»). |
| 🔴 **استضافة مدفوعة** (محمول) | `rtempurl` ينام/يفقد البيانات — **حرج قبل الإطلاق**. |
| **تحقّق إيصال IAP** (webhook) على الباك إند | معلّق — للاعتماد الكامل على entitlement server-driven (الدفع يعمل على الجهاز أصلاً). |
| **`/validate-code`** نشر | معلّق — تأكيد طارق. |
| **الإحالة (affiliate) endpoints** | greenfield — طارق يبني (`summary`/`commissions`/`referralCode`) قبل لوحة الخطّابة. |
| **`Auth/change-password` غير moderator-gated؟** | معلّق — العميل يستدعيه للدورين بلا تمييز؛ تأكيد server-side. |
| **الخطّابة — `/note` 5xx حقيقي أم bug شكل عميل؟** | ⚠️ افحص الـ RAW envelope أولاً (سابقاً `/chat` تغليف مزدوج — إصلاح عميل `4cc7f27`). |
| **روابط «تواصل معنا» الحقيقية** (product) | placeholders حالياً. |
| Verified-badge + «مكتمل» flag | معلّق — الـ UI **مبوَّب جاهز**. |
| Delete-account flow / حدّ الماتشات | غير مؤكد server-side / backend-only. |
| بلد الزميلة / unread لكل بطاقة / مسارات الصور | معلّقة — غير بالـ DTO / تعارض user-images vs profile-images. |
| أشكال colleagues/notifications | **non-blocking** — parsers دفاعية. |

---

## 🔎 جرد round-2 (READ-ONLY، جاهز) — `docs/_plan_drafts/round2_inventory.md`

تدقيق مؤسَّس على الكود لـ 3 شاشات قادمة:
- **Matchmaker User Interests:** شاشة كاملة مدفوعة `RouteNames.matchmakerInterests` (arg `userId`)، تُفتح من أكشن ❤️ الثانوي على كرت المشتركين. **3 تابات one-shot (غير مرقّمة):** توافق نشط / أعجبوا بك / أرسلت إعجاباً. endpoints `matchmaker/users/{id}/matches|/matches/archived|/likes/incoming|/likes/outgoing`. **مرآة read-only — لا CTAs.** الأعضاء المقفولون بلور + «عضو مخفي» + نقر معطّل. **verdict: DS-clean.**
- **User Notifications:** `NotificationsScreen` (`/notifications`)، بلا filters/tabs. 6 أنواع (match/chat/profile/announcement/offer/general) + sub-actions تقود الأيقونات عبر `NotificationTileVisuals`. **لا حالة قراءة باك إند** (heuristic محلي عبر `NotificationBadgeCubit`). نقر → `NotificationDeepLink` يحلّه الـ shell بتبديل تاب. **verdict: DS-clean.**
- **Matchmaker Notifications:** `MatchmakerNotificationsScreen` (`/matchmaker/notifications`)، توأم شبه-مطابق للمستخدم لكن **تطبيق منفصل** (لا widget مشترك). **القطعة المشتركة الوحيدة: `NotificationTileVisuals`** (أيقونة+نبرة) — تعديلها يمسّ الدورين. من صندوق الخطّابة، **صفوف chat فقط تنقّل**؛ صفوف الحالات no-op. **verdict: DS-clean.**
- **blast radius:** تطبيقان منفصلان؛ `NotificationTileVisuals` هو الملف المشترك الوحيد الذي يُعيد صياغة الدورين.

---

## 🔒 القرارات الثابتة (الكود لا يعرفها — احترمها)

- **الخلفية `#F8F8F8`** (`creamCanvas`) — نهائي (تجاوز مقصود لدليل الهوية).
- **الهوية:** واين `#431C33` · `wineLight #4A1F38` · ذهبي `#E4C094` · `goldDeep #B18454` (مقروء تحت الأبيض). success/verified = ذهبي (لا أخضر). overlays = واين غامق (لا أسود). danger = `#A33949`.
- **نظام التصميم = المصدر الوحيد (صفر تسامح):** لا `AppColors`/`AppTextStyles`/`AppDimens`/`Color(0x…)`/Material colors — الملفات القديمة محذوفة. توكن ناقص؟ **أضِفه** للـ DS.
- **إضافات DS هذه الجلسة كانونية:** `QeranMonogram` · `QeranStepper` · `QeranBottomSheet` · `QeranRangeSlider` · `MatchmakerFactChips` · `MatchmakerCardActionBar` · `SettingsProfileHero`/`Row`/`LogoutCard` · توكن `gold18` · danger ramp.
- **Loaders:** `QeranLoader` (قوسان واين+ذهبي) بكل مكان؛ loaders الأزرار المملوءة **أحادية اللون** للتباين.
- **تسمية العروض:** `<planPrefix>-<discountPercent>` — **نفس المعرّف على جوجل وApple** (العقد الحامل لـ `/validate-code`).
- **نوع عرض iOS: Offer Codes** لا Promotional Offers (الأخيرة تستثني الجدد فتفشل بصمت).
- **مجموعة اشتراك Apple تحتاج Localization خاصّاً بها** (عربي «باقات قِران»، إنجليزي «Qeran Packages») — وإلا تبقى «Missing Metadata».
- **مصدر التصميم = Claude Design (HTML) في `docs/_design/`** — Figma متقاعد. الشكل من المرجع، الألوان/الخط/المسافة من هويتنا. (`_design/` غير متتبَّع — ثقيل.)
- **`QeranButtonVariant` = 7 variants** — `DESIGN.md` قد يكون stale بعدد 6.
- **ثنائي الاتجاه دائماً:** `*Directional`؛ لا left/right يدوي؛ لا `Directionality` widget؛ لا double-flip. أرقام/إيميلات/أوقات LTR tabular. سهم الرجوع `chevron_left_rounded`. **OTP دائماً LTR**.
- **backend-driven / dynamic (مُحترَم end-to-end هذه الجلسة):** ارسم فقط ما يدعمه الباك إند. الجنسية حُذفت من شيت المشاركة (ليست حقلاً بنيوياً)؛ verified/complete مبوّبان على أعلام مفقودة؛ labels المراحل من نفس ملف الـ timeline.
- **AUTH FIELD STYLE (لا توحّده):** حقول auth = `pill` + بلا border + ظل `e1` — يختلف عمداً عن أسطح غير-auth (`paper` + `hairline`).
- **تواصل user-to-user مباشر = ممنوع** — كل المحادثة عبر الخطّابة (`/api/chat/my-matchmaker`).
- **أكواد الإحالة داخلية** — عبر dashboard/باك إند، لا store offer codes.
- **الدفع = IAP / RevenueCat**.
- **— الخطّابة (حرجة، غير مستنتَجة):**
  - **عرض الملف معكوس:** `GET /matchmaker/users/{id}/profile` (بلا `isBlurred`). **ممنوع** `/discovery/profiles/{id}` (يرجّع `matchingScore` بلا معنى + يُحتسب على حدّ المشاهدات). التوحيد = building-blocks مشتركة لا شاشة مشتركة. الملف عرض-فقط. صور الخطّابة غير مغبّشة دائماً.
  - **تعديل الإجابات النصية inline** عبر `TextAnswerEditScope` (InheritedWidget) — قلم لـ `type==text` فقط، فقط إذا رُكّب الـ scope (host خطّابة، محصور `pendingReview`/`rejected`). المستخدم لا يركّبه أبداً.
  - **مرآة الاهتمامات read-only** — building blocks لا كروت المستخدم؛ `isLocked` يُخفي الطرف الآخر **بلا CTA اشتراك** (الخطّابة ليست المشتري). **مصدر labels المراحل = `matchmaker_case_labels.dart`** (نفس الـ timeline — صفر تباعد).
  - **فلاتر الاستكشاف/الحالات = شيتات موازية** — sub-widgets فلتر discovery فقط، بلا لمس discovery. فلتر الحالات **client-side** (`pageSize=100`). فلاتر النطاق مُسقَطة بالاستكشاف.
  - **الزميلات = استنساخ ستاك محادثات المستخدم**؛ parsing دفاعي (`name ?? fullName`) — **CODE WINS**.
  - **إشعارات الخطّابة — unread محلي:** `max(0, currentTotal − lastSeenCount)` بـ prefs؛ badge cubit **singleton**. لا نقطة unread لكل صف.
- **فلتر الباقات (Users «مشتركون»):** شريط chips ديناميكي من `GET /users/subscription-plans` (لا hardcode)؛ تمييز بالاسم لا اللون؛ فلترة **server-side عبر `?planId=`**؛ DI = factory.
- **`QeranConfirmDialog` = dialog التأكيد الموحّد** — أزرار تلتفّ + `IntrinsicHeight`. **يفوز حتى على الـ handoff:** إغلاق الحالة اقتُرح شيت دوم مخصّص → أُبقي على `QeranConfirmDialog` (نمط danger موحّد؛ الاتساق يغلب المخصّص).
- **CODE WINS على الـ handoff لمّا للكود ميزة حقيقية أغفلها الـ handoff:** read-receipt «قرئت» + chip نتيجة التوافق على كرت الملف-المشارَك + صورة الرأس — كلها اقتُرح حذفها، كلها **مُبقاة ومُعاد تنسيقها**. الـ handoff design brief لا feature list.
- **لا تُكوميت أبداً:** `.metadata` · `android/…/MainActivity.kt` · `web/` · `_design/` · token file (`qeran_colors.dart`) بلا تأكيد · شغل أنس (gender/Interests round-2/الترجمات المعلّقة).

---

## ⚠️ Gotchas (تنبيهات)

- **⭐ mojibake بالكونسول (����) ≠ ملف تالف:** stdout الويندوز cp1256 يطبع UTF-8 سليماً غلطاً. تحقّق بـ hexdump أو rootBundle قبل افتراض فساد الملف. **ضيّع وقتاً هذه الجلسة قبل تأكيد سلامة ar.json.**
- **⭐ Hot reload (`r`) لا يعيد تحميل الأصول:** تغييرات الترجمة/JSON تظهر فقط بعد hot **RESTART** (`R` كبيرة) لأن `EasyLocalization.ensureInitialized()` يعمل في `main()` فقط. **كلّف تشخيصاً حين ظهرت مفاتيح جديدة كأسماء خام.**
- **⭐ CODE WINS على الـ handoff** لمّا للكود ميزة حقيقية شغّالة أغفلها الـ handoff (انظر القرارات) — والـ«مكوّن واحد لكل غرض» يغلب المخصّص.
- **رسائل الـ commit بتكذب:** تأكّد من الكود دائماً.
- **⭐ `IndexedStack` يحفظ الحالة عبر التابات *و* push/pop** — لا تفترض إعادة جلب لكل تنقّل.
- **⭐ أشكال wire الخطّابة تخالف افتراض المستخدم/discovery** — parser منسوخ يفشل بصمت (TypeError → «خطأ غير متوقع»)، مش بالضرورة فشل سيرفر. سجّل الـ RAW envelope أولاً. أمثلة: `/chat` (`4cc7f27`) · `/explore/filters` (`facb32a`).
- **filtered-staging يتخطّى المفاتيح الجديدة بصمت:** لمّا تضيف مفاتيح ترجمة، تأكّد أنها فعلاً staged (ظهرت كأسماء خام هذه الجلسة).
- **نجاح `submitAnswers` يجب أن يُبطِل cache الـ edit-form** — أبقِ الـ hook.
- **`.then` على `executeApiCall<T>`** يُسقط الاستدلال لـ `dynamic` لو `T` generic — ثبّت الـ type parameter.
- **Profile hub — تاب العرض ما بيتحدّث بعد الحفظ:** `MyProfileCubit` داخل `ProfileSelfView` (ارفعه فوق الـ hub). لسا غير معمول.
- **الأرقام العربية ببناء Gradle:** ثبّت `-Duser.country=US -Duser.language=en`.
- **⭐ الباك إند يرسل UTC بلا `Z`:** حلّلها كـ **UTC** (أضف `Z` إن غابت)، وقارن بالـ UTC دائماً. نفس البق الكامن كان **app-wide** (8 مواقع تحليل طابع) — مُركزَن الآن في `server_datetime.dart` (حارس `hasTz`). فشل التحليل = حالة **مجهولة** (`hasReliableExpiry=false` → كرت خطأ)، لا «منتهٍ».
- **⭐ emits غير المتزامنة بالـ Bloc — لا تُطلق عن snapshot قبل await:** اقرأ الحالة **الحيّة** وقت الـ emit والمس **حقلك فقط** (index / error)، وإلا تتصادم emits متزامنة (prefetch يضيف صفحة مقابل advance يحرّك المؤشّر). `copyWith` عن snapshot قديم أفسد **حقلين** معاً (profiles + isPrefetching) → loader دائم بالديسكفري. (`pass()` المتزامن لم يكن عرضة.)
- **⭐ `Equatable.toString` يطبع props موضعياً:** الـ getters المحسوبة (مثل `hasMore`) **ليست** في الـ tuple — لا تسئ قراءة علم موضعي على أنه حقل آخر (ضاع وقت تشخيص مرّتين هذه الجلسة).
- **⭐ اشتراكات Google Sandbox الاختبارية:** تجديد كل **5 دقائق**، حتى 6 تجديدات (~30 دقيقة) ثم إلغاء تلقائي — الاشتراك الجديد **ينتهي فعلاً** بعد 5 دقائق من الشراء. اختبر داخل النافذة، ولا تخلط انتهاء Sandbox الحقيقي مع بق الوقت.

---

## ⚠️ أعلام التحقّق التشغيلي (على حساب Moderator حيّ — لا شيء يحجب)

- deep-link «الحالات» من الصندوق لتاب الحالات (shell scope للـ route المدفوع).
- أيقونات إشعارات per-action + توجيه `data` معبّأ — يحتاج إشعار **post-fix** + push حقيقي (`adb` لا يحاكي `onMessageOpenedApp`/`getInitialMessage`).
- خيوط الزميلات realtime — تحتاج حسابَي Moderator حيّين.
- سيغمنت الجنس بالاستكشاف يفلتر فعلاً (Male/Female للباك إند).
- تاب «بالانتظار» (Users) — كان 0 مستخدمين؛ نفس مسار كود الكرت.
- نص `matchmaker_users_age_years` = «عندي {age} سنة» (صيغة متكلّم — POV غلط لعرض مستخدم؛ إصلاح صياغة على جهتنا).
