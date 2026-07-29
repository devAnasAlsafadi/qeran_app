# Qeran — Handoff (وين وصلنا)

> **الغرض:** الطبقة غير المستنتَجة من حالة المشروع — النية، القرارات الثابتة، الخطوات الجاية، الـ gotchas، بنود الباك إند، بيانات الحسابات/الاعتمادات. حالة الكود نفسها تُستنتَج من الكود + legacy-grep.
> اقرأه أول شي كل جلسة. حدّثه نهاية كل مهمة.
> **آخر تحديث: 29 يوليو 2026** — **إصدار متجر `1.0.7+9`**، بعد **قوس دمج شاشة الاستكشاف** (Discovery + الملف الكامل صارا شاشة واحدة full-bleed) + **موجة صقل on-device** (R1–R6 + الطيّة القابلة للانطواء + شريط الأزرار + تلميح السكرول) + **حالة القراءة المحلية للإشعارات** + **إعادة تحميل التطبيق كاملاً عند تبديل اللغة** + **موجة إصلاحات الخطّابة (M1/M2 + 12 بنداً)** + **جولة تنظيف ما-قبل-المتجر**. analyze نظيف + **867 اختباراً أخضر** + AAB إصداري مبنيّ وموقَّع. التحديث السابق: موجة أمان الإطلاق (13 بنداً CODE-NOW) + تنظيف Part A (كانت عند `3017dbb`). **الجاي = رفع `1.0.7+9` على Play + بنود NEEDS-MAC + جاهزية المتاجر + تبديل الاستضافة + ترتيب deck الاستكشاف (طارق).**

---

## 🎯 الحالة الحالية — الصورة الكبيرة

**تطبيق الخطّابة صار مكتملاً بصرياً 🏁** — **كل 11 شاشة أساسية + كل 3 شيتات** أُعيد تصميمها وشُحنت. **مرحلة الصقل البصري (Design Polish) انتهت** (onboarding + auth + gender + Interests/Match-success + كل شاشات الخطّابة). **وموجة أمان الإطلاق (كل الـ 13 بنداً CODE-NOW) شُحنت ومدفوعة** — التطبيق صار متوافقاً مع سياسات UGC للمتجرين على مستوى الكود.

- **Google Play:** العروض **حيّة end-to-end** (3 اشتراكات + 30 عرضاً Active؛ شراء حقيقي مُختبَر على الجهاز). أندرويد مُقوّى (`usesCleartextTraffic=false` + إسقاط `READ_MEDIA_IMAGES`).
- **Apple App Store:** الـ metadata + إعدادات الـ 30 عرضاً **مكتملة**؛ ملفّات `PrivacyInfo.xcprivacy` + `Products.storekit` + مفتاح export-compliance **مؤلَّفة بالكود**؛ **ربط Xcode + build لا يزالان NEEDS-MAC**. Custom Codes معلّقة على Mac.
- **الامتثال (UGC/سلامة):** Report + Block + بوّابة 18+ + موافقة تسجيل + حذف حساب (مستخدم وخطّابة) — **كلها حيّة بالكود** على عقد طارق.
- **وثيقتا طارق جاهزتان للإرسال** (backend tasks + offers reference).
- **✅ البناء الإصداري مُتحقَّق على الجهاز** — سلسلة إصدارات Play (`1.0.4+6` → `1.0.5+7` → `1.0.6+8`) شُحنت وجُرّبت فعلياً؛ R8/ProGuard آمن، تسجيل الدخول بجوجل يعمل على مفتاح الإصدار (`2e0e232`). **الحاجب القديم «تحقّق البناء الإصداري» صار مُغلقاً.**
- **📦 `1.0.7+9` جاهز للرفع** — AAB مبنيّ وموقَّع، analyze نظيف، 867 اختباراً أخضر.

**الجاي = رفع `1.0.7+9` على Play، ثم بنود NEEDS-MAC (Mac قادم) + جاهزية سياسات المتاجر + تبديل الاستضافة (طارق) + إصلاح ترتيب deck الاستكشاف عند الباك إند.**

---

## 🆕 إصدار `1.0.7+9` + جولة تنظيف ما-قبل-المتجر (29 يوليو)

**السياق:** إغلاق قوس الصقل on-device ثم جولة نظافة كاملة قبل الرفع للمتجر.

**التنظيف:**
- **رُجِعت التشخيصات المؤقتة** (`d1ef148` ← `36bee35` placementCodes · `57e936d` ← `4733434` imageRequestStatus). لم يعد في `lib/` أي `TEMPORARY DIAGNOSTIC`.
- **حُذف ملفّان يتيمان:** `staggered_children.dart` (55 سطراً) + `profile_status_banner.dart` (86 سطراً) — لا مرجع لهما في `lib/` ولا `test/`.
- **أُزيلت `flutter_animate: ^4.5.2`** — اعتمادية **runtime** لم تُستورَد ولا مرة (تُشحن ولا تُستخدَم). أدوات البناء (`flutter_native_splash`, `flutter_launcher_icons`, `flutter_lints`, `change_app_package_name`) **بقيت عمداً** — لا تُشحن، وحذفها يكسر إعادة توليد الأيقونات/الـ splash.
- **الإصدار:** `1.0.6+8` → **`1.0.7+9`** (مؤكَّد داخل الـ AAB: `versionName=1.0.7`, `versionCode=9`).

**نتيجة فحص ما-قبل-المتجر (كلها نظيفة، بلا تغيير مطلوب):**
- صفر `print()` · صفر `TODO/FIXME/HACK` · صفر شاشات debug/test · صفر اعتمادات غير مستخدمة (بعد الإزالة أعلاه) · كل الـ 19 asset مرجَّعة فعلاً.
- `AppLogger` **مقفول بالكامل خلف `kDebugMode`** — لا يُسجَّل شي في الإصدار (لذلك التشخيصات ما كانت تسرّب، لكنها رُجعت كوزن ميت).
- الأسرار خارج git: `android/key.properties` + `local.properties` مُتجاهَلان عبر `android/.gitignore` (**مُتحقَّق بـ `git ls-files`** — غير متتبَّعين).
- `usesCleartextTraffic=false` · صلاحيات المانيفست دقيقة (لا `READ_MEDIA_IMAGES`) · `google-services.json` على `com.qeran.app` · مفاتيح RevenueCat تسقط على مفاتيح الإنتاج · iOS يقرأ الإصدار من `$(FLUTTER_BUILD_NAME)` (يتبع pubspec تلقائياً).
- **حجم الـ AAB 54MB مضلِّل** — منه ~47MB رموز debug (`BUNDLE-METADATA/…/*.so.sym`) + 25MB `proguard.map`؛ **Play يجرّدها ولا تصل للمستخدم.** حجم التنزيل الفعلي = split ABI (~28MB arm64، مقيس سابقاً).

**بند اختياري (لم يُلمَس — قرار منتج):** `android:label="qeran"` — الاسم تحت الأيقونة بحروف لاتينية صغيرة. **ليس ارتداداً** (هكذا شُحنت كل الإصدارات السابقة)، لكن «قِران» أنسب للهوية. غيّره لو بدك.

---

## 🆕 قوس الاستكشاف الموحّد + موجة الصقل on-device (20–29 يوليو — 115 كوميتاً فوق `3017dbb`)

**السياق:** أطول قوس متّصل حتى الآن — إعادة بناء شاشة الاستكشاف من الأساس، ثم دورات صقل مدفوعة بمراجعة على الجهاز (screenshots)، بالتوازي مع 3 إصدارات Play (`1.0.4+6`, `1.0.5+7`, `1.0.6+8`).

### 🃏 دمج الاستكشاف + الملف الكامل في شاشة واحدة (`5648f96` وما بعده)
- **الكرت الموحّد:** صورة نصف-الشاشة تحت شريط الحالة، ثم «الطيّة» بعد نبذة عني، ثم بقية الملف بسكرول داخلي — بدل شاشتين وانتقال Hero.
- **الطيّة قابلة للانطواء (R4):** `ConstrainedBox(minHeight: viewportHeight − offset × 2.0)` فوق `Column(mainAxisSize.min)` — **الفراغ ينكمش تحت الإصبع بدل ما ينزاح لتحت الصفحة.** لا spacer ثابت بحجم الـ viewport (كان يخلق فجوة عملاقة).
- **pill التوافق يُكشَف بالسكرول (R1):** `ClipRect > Align(heightFactor: t) > Opacity` — **صفر ارتفاع عند السكون**، و**يأخذ مكان الاسم** بدل ما يحجز فراغاً (`27e5439`).
- **شريط الأزرار:** استقرّ على **إعجاب 60 / تخطّي 50 / تراجع 50**، الثلاثة على خط أساس واحد (`CrossAxisAlignment.end`). حدود من التوكنز (`wine20` للتخطّي، `wine12` للتراجع، بلا حدّ للإعجاب).
- **تلميح السكرول (`bbf7ee3`):** coach mark — يستنى 2.5 ثانية سكون، يروح مع أول سكرول >24dp، **وما يرجع أبداً** (اللاتش فوق الـ deck فيغطّي كل الكروت). `IgnorePointer` كامل + يحترم reduce-motion. **⚠️ قرار: session-scoped لا محفوظ** — يذكّر مرة كل فتح للتطبيق؛ حوّله لـ persisted لو بدك مرة-واحدة-للأبد (ويلزم إضافته لقائمة المسح عند حذف الحساب).

### 🔔 حالة القراءة المحلية للإشعارات (`2e1c718` + `1c4a6c5`)
- **الجذر:** نقطة الجرس كانت **دايماً ظاهرة** — الـ `BlocBuilder<NotificationBadgeCubit>` سقط لمّا انتقل الجرس فوق الصورة في `5648f96`.
- **القرار المعماري:** فُصلت **«شوهد» (seen)** — تطفي نقطة الجرس، تُسجَّل عند `dispose()` — عن **«مقروء» (read)** — تلوّن الصف. بدون هذا الفصل كان الطلبان (تعليم-تلقائي-عند-الخروج + تعليم-لكل-عنصر) يلغيان بعضهما.
- watermark + `readIds` set؛ زر «تعليم الكل كمقروء» يظهر فقط وفي القائمة غير مقروء.

### 🌍 تبديل اللغة يعيد تحميل التطبيق كاملاً (`e90e6a1`)
`LocaleRebuildScope` (`KeyedSubtree` بمفتاح `locale-<code>`) على محتوى تابات الـ shellين → **إعادة بناء كامل يُعيد ضرب ريكوستات الباك إند** فتتبدّل البيانات الآتية من السيرفر كمان، لا النصوص المحلية وحدها. `setLanguage` صار يرجّع `bool switched` (false على مزامنة الإقلاع البارد، فلا rebuild زائد).

### 👩‍💼 موجة إصلاحات الخطّابة (12 بنداً + M1/M2)
`81524a5` picker المشاركة كان **يُسقط كل مشترك بصمت** · `1e5b384` تسميات أدوار الحالة تتبع الملكية · `ff5df2f` زر طلب الصورة مقود بـ `imageRequestStatus` · `b3c0d40` أكشن إغلاق واحد لكل مرحلة · `8833a4f` تعديل النبذة مسموح على الملفات المعتمدة · `474e01d` فلتر جنس المستلم في picker المشاركة · `cdcba24` تحديث شارة المعلّقات لمّا يغادر صف القائمة · `2077a2f` تصنيف فشل الدخول على `errorCode` لا رسالة السيرفر · `06a52b6` إسقاط shim الـ UNAUTHORIZED العربي.

### 🧩 الاهتمامات/الصفات (`cd9c363` + `1d6d905`)
**«الصفات الشخصية» ما كانت ناقصة — كانت تُعرض بلا عنوان ومدموجة مع الاهتمامات.** `placementCode: 5` يرجع **عنصرين** (`questionId 22` الصفات · `23` الاهتمامات)، و`InterestsSection` كان يفلطح كل `items` في wrap واحد. صار **مجموعة معنونة لكل عنصر**. الشيبس صارت `QeranChipVariant.inside` (أبيض + hairline واين) بدل `interest` الذهبي — **بإعادة استخدام variant موجود** لا بتعديل `interest` المستخدَم في 7 مواضع أخرى.
> ⚠️ **قاعدة من طارق:** لا تفترض عنصراً واحداً لكل مجموعة — كرّر على `items` كلها. و`value`/`display` **String لمّا الخيار واحد و Array لمّا أكثر** — كلا الـ parserين يتحمّلان الحالتين أصلاً (مُثبَّت باختبار).

### 🩹 إصلاحات متفرقة
`958ad1f` الاسم الطويل بقائمة الإعجابات يلتفّ تحت نفسه بدل الاقتطاع (3 أسطر) · `87c0470` الحالة الفارغة المفلترة صار فيها طريق رجوع للفلاتر · `d5b521c`+`105fb24` نبذة عني تلتفّ كاملة · `33ca44b` الشيتات ذات المدخلات ما عادت تفيض تحت الكيبورد · `162b506` حذف الحساب خلف تأكيد نهائي · `2e0e232` تسجيل عميل توقيع الإصدار لدخول جوجل · `66ff22d` تحسينات raster + فكّ الصورة بحجم العرض.

---


**السياق:** بعد تدقيق ما-قبل-الإطلاق (READ-ONLY) → تنفيذ كل الـ 13 بنداً CODE-NOW على عقد طارق لأمان الإطلاق (UGC/امتثال متاجر) + جولة تنظيف Part A (بناء/حجم). **الكل مدفوع** (`origin/main..HEAD` فارغ). **analyze نظيف + 669 اختباراً أخضر + code-review بلا blockers.** 6 كوميتات فوق Part A: `4e8b494` feat(safety) · `2241216` fix(subscriptions) · `4d3043d` build(android) · `62c8541` chore(ios) · `7fe299e` feat(splash) · `3017dbb` chore(gitignore) — و`4405ef9` (Part A) قبلها.

**تنظيف Part A (`4405ef9`):**
- حذف 10 ملفات يتيمة · إزالة 4 حزم غير مستخدمة (`font_awesome_flutter`, `cupertino_icons`, `smooth_page_indicator`, `test`) · حذف pngs الجنس · حذف تعليق ميت + TODO قديم لـ RC.
- **البناء/الحجم:** R8 `minifyEnabled` + `shrinkResources` مُفعّلان بـ `android/app/proguard-rules.pro` جديد (keep rules لـ Flutter/Firebase/RevenueCat) · Montserrat subset لاتيني فقط (~1.1MB) · pngs الجنس → WebP.
- **الحكم المُسجّل:** الـ APK الشامل بقي ~ثابتاً (69.4→69.5MB — المكتبات الأصلية تهيمن)؛ **الربح الحقيقي = تقسيم ABI** (split arm64 = 28.1MB، ~59% أصغر، يأتي من الـ AAB على Play). قيمة R8 هنا = نظافة سياسة/تعتيم Play لا البايتات.

**موجة أمان الإطلاق (13 بنداً CODE-NOW):**
- **بوّابة العمر 18+:** picker يوم الميلاد يقصّ لـ `currentYear-18` (`question_date_widget.dart`)؛ `UNDERAGE_NOT_ALLOWED` مُصنَّف per-datasource → إشعار 18+ مُوطَّن عند الإرسال. + إقرار «عمري 18+» **مطويّ داخل checkbox الخصوصية/الشروط** يحرس التسجيل.
- **موافقة التسجيل:** «سياسة الخصوصية» + «شروط الاستخدام» صارا قابلَي النقر (deep-link لتابات `LegalScreen`).
- **Report (بلاغ):** شريحة كاملة `lib/features/report/` → `POST /api/reports`، تصنيف errorCode (`VALIDATION_ERROR`/`TARGET_USER_NOT_FOUND`)، picker سبب (enum) + شيت ملاحظة. مداخل: ⋮ البروفايل + معرض الماتش.
- **Block (حظر):** شريحة كاملة `lib/features/block/` → حظر/فكّ/قائمة، `TARGET_USER_NOT_FOUND` **محايد (لا يكشف حالة الحظر أبداً)**، ⋮ البروفايل + شاشة الإعدادات→المحظورون (`/settings/blocked-users`) + teardown على الديسكفري عند الحظر.
- **حذف حساب الخطّابة:** `DELETE /api/matchmaker/me/account` (Moderator) — يطابق حذف المستخدم (تأكيد-مكتوب→حذف→unlink→wipe→login). يرقّي مسار الـ deactivate-only القديم.
- **Restore-purchases** صار ظاهراً على شاشة الباقات/الـ paywall (شرط Apple).
- **أندرويد:** `usesCleartextTraffic=false` + إسقاط `READ_MEDIA_IMAGES` (image_picker يستخدم Photo Picker النظامي 13+).
- **iOS (مؤلَّف بالكود؛ ربط Xcode لا يزال NEEDS-MAC):** `PrivacyInfo.xcprivacy` (`NSPrivacyTracking=false` + أنواع البيانات المجموعة + required-reason APIs) · `ITSAppUsesNonExemptEncryption=false` في Info.plist · `Products.storekit` (3 اشتراكات، أسعار/فترات صحيحة).
- **Web:** `docs/legal/account_deletion.html` (صفحة حذف عامّة ثنائية اللغة — **تُستضاف منفصلة، لم تُكوميت للتطبيق؛ تبقى في working tree**).
- **Splash:** Lottie جديد آمن-للموبايل موصول — `assets/animations/logo_qeran_v3.json` + `splash_screen.dart` يشير إليه؛ الـ hang-proofing محفوظ (dual-gate + errorBuilder + timeout + reduce-motion). (gotcha بالأسفل.) `logo_qeran.json` القديم (~91KB) صار بلا مرجع لكن **مُبقى كـ rollback — احذفه بعد تأكيد v3 على الجهاز.**
- **`data.json`** حُذف + gitignored (dump API قديم لم يعد مطابقاً لعقد طارق).

---

## 🆕 إكمال الاشتراكات + لوحة الإحالة UI + تنظيف + موجة إصلاحات الخطّابة (18 يوليو — **كلها مدفوعة**، `origin/main` عند `41a3b5d`)

**السياق:** إغلاق ذيل موجة الاشتراكات (P2/P3 + حارس الباقة المجانية) + بناء واجهة لوحة الإحالة على عقد طارق الحيّ + جولة تنظيف + موجة إصلاح باگات على تطبيق الخطّابة. **الكل مدفوع** على `origin/main` (`origin/main..HEAD` فارغ).

**الاشتراكات — إغلاق الذيل:**
- **✅ P2 (شُحن):** تعريف الباقة بالـ `tier` لا بالاسم (حُذف تطابق `'vip'`/`'basic'`) · dedup كرت الباقة المجانية (كانت تظهر من `/plans` **و** ككرت ثابت) · owned-pricing على شارة «باقتك» (عبر `currentSub.pricing`) · **backoff** لإعادة جلب `/current` بعد الشراء (retry محدود على نافذة الـ 204 اللحظية بعد الشراء).
- **✅ P3 (شُحن):** تبنّي نقاط `featuresAr/featuresEn` من الباك إند لعرض ميزات الباقة (backend-driven)، مع الـ checklist الرقمي القديم كـ fallback.
- **✅ حارس الباقة المجانية بـ P1b (شُحن):** شيت حدّ تبادل الصور **لا يدّعي التجديد أبداً لمستخدمي `isFree`** — pill التجديد + الـ subtitle مبوّبان الآن على `!isFree` (كان الـ subtitle غير مشروط). يغلق نصف الحالة الحدّية free-trial؛ النصف الآخر (أي errorCode يرجع فعلاً) **لا يزال بانتظار طارق** — انظر المعلّقات.

**لوحة الإحالة (affiliate) UI (`6deb24d`)** — بُنيت على عقد طارق الحيّ:
- **كرت نسبة العمولة:** `commissionRate` + `commissionType` (`percent`/`fixed` — **forward-safe**؛ نوع مجهول/فارغ → `null`)؛ صيغة `%` أو `<n> USD`؛ `rate == null` → «**—**».
- **كرتا عدّاد:** `registeredUsersCount` = «سجّلوا» · `codeUsedCount` = «تحوّلوا».
- **العملة = حقل باك إند، دائماً USD** (قرار منتج مؤكَّد — لا تُحوَّل ولا تُخفى).

**جولة تنظيف:**
- **13 اختباراً قديماً أُصلح** (`http`→`https` origin · `LocaleKeys` · provider الـ sub-cubit) + حذف اختبارات template/legacy ميتة.
- حذف `CheckPremiumStatusUseCase` الميت · توطين `_UpgradeFeedBanner` · toast الإعجاب offline صار يميّز `OfflineFailure`→`errors_offline`.
- likes round-2: تاب نشط واين · حدّ match هيرلاين · frost واين على أفاتار الصورة المخفيّة.

**موجة إصلاحات الخطّابة (هذه الجلسة):**
- **`f7d15d7` fix(matchmaker):** تحية الهوم تعرض اسم الخطّابة عبر `/matchmaker/me` — **payload الدخول لا يحمل اسم moderator، و`StorageKeys.userName` لا يُحفظ للـ moderators أبداً** فكان لا بد من جلبه من `/matchmaker/me`.
- **`41a3b5d` refactor(matchmaker):** إعادة رصّ التحية — **الاسم هو الـ hero** (كبير واين) والسلام سطر صغير مكتوم تحته (كان inline «سلام، اسم»). حُذفت مفاتيح `*_named` (ar/en + generated). بلا اسم → السلام وحده كسطر hero.
- **`5d5d5bc` fix(matchmaker):** تفاصيل حالة التوافق **تعيد استنتاج الحالة من قائمة الحالات الحيّة** (المغذّاة realtime — `context.watch` + استنتاج بـ `caseId`) بدل snapshot مُمرَّر → يمنع طلب same-state البائت (`3→3`) + وميض النجاح-ثم-الفشل. **بلا شبكة إضافية.** backstop: استرداد `INVALID_STATUS_TRANSITION` الرشيق للحالات التي تغادر القائمة أثناء العرض.
- **`37dcd59` fix(realtime):** خدمتا chat + matchmaker realtime تسلسلان connect/disconnect عبر **طابور عمليات** (`stop()` لا يسابق `start()` أبداً) → يصلح «Failed to start the HttpConnection before stop() was called» على open→leave السريع، الذي كان قد يعطّل تسليم الرسائل الحيّة. + اختبارات re-entrancy لكلا الخدمتين.

---

## 🆕 موجة الاشتراكات + الحدود + Paywall (17 يوليو — P4+P0+P1؛ **الكل مدفوع الآن** ضمن `..41a3b5d`)

**السياق:** بعد وصول **عقد الباك إند الكامل من طارق (حيّ الآن)** — جولة تدقيق READ-ONLY ثم إصلاح/بناء على نظام الاشتراك/الحدود/الـ paywall. كلها plan-first + مراجعة بصرية AR-RTL/EN-LTR + كوميت ذرّي. (كل force مؤقّت للمراجعة أُزيل قبل الكوميت وتُحقّق من نظافة الـ diff.)

**ما شُحن (بترتيب التبعية):**
- **P4 (`65c434d` + `fd846cd`) fix+refactor(subscriptions):** محدّد تسعير VIP (شهري/3-شهور) مُركَّب؛ سعر الكرت مربوط بالتسعير المختار (كان **يعرض 149.90 ويشحن 349.90**). استُخرج `_PlanCard`/`_FreePlanCard` لملفات `part` (الرئيسي 343→94) + dedup لـ `_PillBadge`. ملف الكرت قُبِل عند **235 سطراً** (>200؛ استخراج `_PlanCardHeader` هو الرافعة إن لزم).
- **P0.1 (`ce2cad5`) fix(subscriptions):** sentinel العدّاد اللامحدود `int.MaxValue`→**`v < 0`** (الباك إند يرسل `-1`). كل عدّادات VIP اللامحدودة كانت تُعرَض «**-1**» حرفياً. الاختبارات قُلبت.
- **P0.2 (`3293fad`) feat(likes):** تصنيف فشل الإعجاب بـ errorCode (الكامل: `SUBSCRIPTION_REQUIRED`/`LIKES_QUOTA_EXCEEDED`→Paywall · `LIKE_ALREADY_EXISTS`→AlreadyPending · `SAME_GENDER_NOT_ALLOWED`→GenderMismatch · `TARGET_USER_NOT_FOUND`/`LIKE_NOT_FOUND`→UserUnavailable)، العربي fallback. أُضيف `DAILY_VIEWS_EXCEEDED` + `PHOTO_EXCHANGE_LIMIT_REACHED` للكتالوج. **إصلاح بق كامن:** إعجاب مُبوَّب راجع HTTP 200 `{status:0}` كان يُقرأ `LikeAccepted(likeId:'')` → صار محروساً بـ `status==0`/errorCode غير فارغ.
- **QeranHeroBadge refactor:** استُخرج hero (ring+disc+glyph) لـ widget DS مشترك ثنائي النبرة (`soft`|`prominent`)؛ الـ paywall **byte-identical** (soft)؛ `prominent` لأسطح P1. أُضيف `QeranStrokes.emphasis = 2.5`.
- **P1a (كوميتان — state + screen، `f20cfc9`+`4b1e08a`) feat(discovery):** حالة «نفدت مشاهدات اليوم» شاشة-كاملة داخل الفيد. `DiscoveryDailyLimit(resetAt)` (الـ datasource يقرأ `DAILY_VIEWS_EXCEEDED` عبر `getRaw` + يحلّل `data.resetAt`؛ typed failure في `executeApiCall`) + `DiscoveryDailyLimitView` + widget `ResetCountdown` (Timer 30s، فصحى مثنّى/جمع: ساعة/ساعتين/ساعات · دقيقة/دقيقتين/دقائق). يُرسَم داخل الـ shell (bottom nav يبقى)؛ أزرار الأكشن مخفيّة صحّ على هذه الحالة (+ على failure/terminal-empty). **ملاحظة: العدّاد يقرّب لأقرب ساعة (`round()`) — floor قرار تصميم مؤجَّل.**
- **P1b (كوميتان — outcome + sheet، `981885f`+`5cd0974`) feat(likes):** حدّ تبادل الصور لـ**مشترك** عند السقف. `PhotoExchangeRequestLimitReached` outcome + تصنيف، و `PhotoExchangeLimitSheet` على `QeranBottomSheetScaffold` (**لا** إثقال الـ paywall — يحتاج إغلاق + شارة باقة + pill تجديد + سطر ترقية). تاريخ التجديد يعتمد `CurrentSubscription.expiresAt`. النبرة «**ترقية**» لا «اشترك». شرطي backend-driven: شارة الباقة تُخفى بلا اسم؛ pill التجديد يُخفى إن `!hasReliableExpiry`. (الملف قُسِّم part/part-of → 167+82 سطراً.)

**🔭 مفتوح على الأفق (موجة الاشتراكات — غير حاجب، عدا الـ free-trial أعلاه):**
- **✅ P2 (شُحن — 18 يوليو):** `tier` بدل الاسم · dedup الباقة المجانية · owned-pricing على «باقتك» · backoff لجلب `/current` بعد الشراء. (تفاصيل: قسم 18 يوليو.)
- **✅ P3 (شُحن — 18 يوليو):** نقاط `featuresAr/featuresEn` من الباك إند (checklist الرقمي fallback).
- **follow-up: تغطية الحدّ اليومي وسط-الرصّة** — مستخدم بلا-اشتراك جلب الصفحة 2 مسبقاً ثم بلغ السقف وسط الرصّة لن يرى شاشة الحدّ حتى تنفد الكروت المحمّلة (مُعلَّق كتعليق كود بـ `discovery_cubit`).
- **قرار تصميم مؤجَّل:** `ResetCountdown` `round()` مقابل `floor()` لعرض الوقت المتبقّي.
- **اختبارات مكسورة سابقة (ليست منّا):** 6 فشل بـ `discovery_next_card_peek_test.dart` (`DiscoveryImagePanel not found`) — مُعاد إنتاجها على HEAD مع stash تغييراتنا؛ تستحق نظرة منفصلة.
- **تصاميم Claude Design (`docs/_design/*.dc.html`):** «Daily Views Limit» + «Photo Exchange Limit» (مستهلكان بـ P1)، و«Affiliate & Referral» (مسار منفصل).

---

## 🗓️ جلسة الدفع + إصلاح الديسكفري (17 يوليو — سابقة بنفس اليوم — commits `40d1089..d8fb097`، مدفوعة)

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
- `splash_screen.dart`: **الـ native splash حيّ الآن**؛ splash الـ Lottie بـ Flutter (هذا الملف) **WIP غير مكوميت** بانتظار Lottie مُعاد التصدير آمن-للموبايل من مصمّم الموشن (أُرسل دليل تصدير كامل: **لا** track mattes/expressions/effects، استخدم trim paths، تحقّق في معاينة LottieFiles). **لا تُضِعه.**
- likes round-2 (4 ملفات): `likes_segmented_tabs.dart` · `match_card.dart` · `match_card_avatar.dart` · `qeran_strokes.dart` (توكن جديد) — صقل بصري لخصوصية الصور/التابات، **غير مُراجَع بصرياً**.
- **مستثنى أيضاً:** `data.json` · `docs/_design/` · `web/` · حذف `_archive/*.md` (لا تُكوميت).

**حالة ميزة الاشتراك:** ~90% مكتملة + شغّالة، **لا stubs/TODOs**. المتبقّي = gaps B/C (تأكيد باك إند، بجدول طارق) + hero النجاح ثابت (cosmetic follow-up).

> **ملاحظة:** شاشة اهتمامات الخطّابة (redesign) مكتملة ومدفوعة أصلاً — `e49455b feat(matchmaker): redesign user-interests screen onto the design system`. **لا تُعالَج ثانيةً.**

---

## 🔴 معلّقات فورية (تُحَلّ أول الجلسة الجاية — خطر/حاجب)

- ✅ **كل الكوميتات مدفوعة** — `origin/main` عند `1.0.7+9`، `origin/main..HEAD` فارغ.
- ✅ **البناء الإصداري مُتحقَّق** (كان حاجباً) — 3 إصدارات Play شُحنت وجُرّبت على الجهاز منذ ذاك؛ R8 آمن ودخول جوجل يعمل على مفتاح الإصدار.
- 🔴 **حاجب — الاستضافة (أعلى حاجب متبقٍّ):** base URL لا يزال `https://qeranadmin-001-site1.rtempurl.com/api/` — استضافة مؤقتة تنام وتفقد البيانات. الانتقال لاستضافة مدفوعة ثابتة = **تغيير سطر واحد** (`lib/core/api/end_points.dart:2`) + rebuild. **أنس يأخذ الـ base URL الجديد من طارق.**
- 🟠 **ترتيب deck الاستكشاف (بانتظار طارق — تشخيص مكتمل):** الكروت **تتكرّر من الأول كل فتح للتطبيق**. **العميل بريء ومُتحقَّق:** التخطّي يضرب `POST /api/discovery/skip/{id}` (موثَّق كدائم) والإعجاب مُنتظَر ومُثبَت الحفظ (`LIKE_ALREADY_EXISTS`). المشكلة في استعلام `GET /Discovery`. **التوصية المُسلَّمة:** (1) استثنِ المُعجَب-بهم/المتطابقين؛ (2) رتّب على طبقات — جديد → مُشاهَد → مُتخطّى بعد فترة تهدئة؛ (3) **الترتيب لازم يثبت عبر صفحات الجلسة الواحدة** (إعادة الترتيب لكل طلب تكسر الـ pagination)؛ (4) أكّد أن عدّاد المشاهدات اليومي يحسب الملف **مرة واحدة لكل (مستخدم، هدف)** — حالياً السقف اليومي يُحرق على ملفات مُعاد تقديمها.
- 🔴 **حاجب — الحالة الحدّية free-trial بـ P1b (بانتظار طارق):** «مستخدم تجربة مجانية (اشتراك مجاني نشط) استهلك 5 تبادلات وطلب المزيد — يرجع `SUBSCRIPTION_REQUIRED` أم `PHOTO_EXCHANGE_LIMIT_REACHED`؟» **حارس `isFree` شُحن (18 يوليو):** الشيت لم يعد يدّعي التجديد لمستخدمي `isFree` (pill التجديد + الـ subtitle مبوّبان الآن على `!isFree`). لكن إن كان الكود الراجع فعلاً `PHOTO_EXCHANGE_LIMIT_REACHED` فقد يحتاج **نسخة تجربة-مجانية مميّزة** في النسخ. **لا تُغلق قبل تأكيد طارق أي كود يرجع فعلاً.**

1. **وثيقتا طارق جاهزتان لكن لم تُرسَلا:**
   - `docs/_plan_drafts/TARIQ_backend_tasks.md` — ⚠️ **يحتاج إصلاح سطر مكسور في قسم 2.2 قبل الإرسال:** رأس `GET /api/matchmaker/me` مشوَّه (ناقص `**` البادئة + backtick) — نسّقه مثل باقي رؤوس الـ endpoints: `` **`GET /api/matchmaker/me`** ``.
   - `QERAN_OFFERS_TARIQ.md` — مرجع الـ 30 عرضاً (أنس يملكه محلياً من Web chat؛ **ليس في الريبو** بعد).
2. **جولة round-2 (3 شاشات جديدة للتصميم):** Matchmaker User Interests + User Notifications + Matchmaker Notifications. **الجرد READ-ONLY جاهز** في `docs/_plan_drafts/round2_inventory.md`. **التصميم الفعلي غير مبدوء.**
3. **✅ تعديل Dashboard (اسم الخطّابة مع/مكان تحية السلام) — شُحن** (`f7d15d7` + إعادة الرصّ `41a3b5d`). **الاسم من `/matchmaker/me` لا `UserSessionCubit`** — الأخير فارغ للـ moderators (payload الدخول بلا اسم moderator، و`StorageKeys.userName` لا يُحفظ لهم). الاسم صار الـ hero والسلام سطر مكتوم تحته.
4. **gender re-skin** — لا يزال محجوباً على PNGs شفّافة (Gemini يبيّض «الشفّاف» كـ checkerboard مطبوخ — يحتاج remove.bg أو Photopea). ⚠️ **لم يعد في working tree** — شجرة العمل نظيفة تماماً، فلو انعمل شي منه لازم يُعاد.
5. ~~ملفات Interests round-2 غير مكوميتة~~ — ✅ **مُغلق**، كلها مكوميتة وشجرة العمل نظيفة.
6. **iOS Custom Codes محجوبة** على توفّر Mac + App Review + سيرفر توقيع JWS من طارق.

---

## ▶️ الخطوة الجاية

**قوس الاستكشاف الموحّد + موجة الصقل + جولة التنظيف = مكتملة ومدفوعة. `1.0.7+9` جاهز للرفع.** أولويات الجلسة الجاية بالترتيب:
0. **🏪 ارفع `1.0.7+9` على Play** — `build/app/outputs/bundle/release/app-release.aab` (مبنيّ وموقَّع؛ أعد البناء بعد أي تغيير للـ base URL).
0.5 **📨 أرسل لطارق البنود الثلاثة العالقة:** ترتيب deck الاستكشاف (التوصية بالأعلى) · migration `AddImageRequestStatus` · إضافة `gender` لـ endpoints قوائم مستخدمي الخطّابة.
1. ~~تحقّق البناء الإصداري على الجهاز~~ — ✅ **مُغلق**، 3 إصدارات Play شُحنت وجُرّبت.
2. **🩹 بنود code-review للإصلاح (should-fix، ليست blockers):**
   - **#1 teardown الحظر موصول فقط بالديسكفري** — likes-received + البروفايل المُشارَك من chat لا يستهلكان الـ block-return، فالمحظور يظهر بائتاً حتى إعادة تحميل يدوية (الباك إند صرمه أصلاً). إصلاح #1 لكل النداءات هو الجذر.
   - **#2 ⋮ Report/Block يظهر على البروفايل المفتوح من chat** (خارج النطاق المتّفق «لا أكشن داخل chat») — نفس جذر #1؛ إصلاحه يُلغيه.
   - **#3 picker العمر بدقّة السنة** — ميلاد في سنة القطع قد يكون 17 وقابلاً للاختيار؛ `UNDERAGE_NOT_ALLOWED` على السيرفر هو البوّابة الفعلية.
   - **nits:** #4 شيت البلاغ يبقى مفتوحاً على `TARGET_USER_NOT_FOUND` · #5 خطأ قائمة المحظورين يعرض رسالة الباك إند الخام عبر `.t()`.
3. **🔧 NEEDS-MAC (Mac قادم):** SIWA capability + aps-environment + IAP capability · ربط `CODE_SIGN_ENTITLEMENTS` في `project.pbxproj` · إضافة `PrivacyInfo.xcprivacy` للـ target · إسناد `.storekit` للـ scheme · build على iOS 26/Xcode 26 · archive/upload.
4. **🏪 المتاجر (بتنسيق منفصل):** Play Data Safety + Apple privacy labels · تصنيف عمري (17+/Mature) · روابط metadata (سياسة الخصوصية + صفحة الحذف) · حسابات تجريبية للمراجعين (طارق — مستخدم + Moderator ببيانات واقعية، تُبقى حيّة) · تبديل الاستضافة (طارق).
5. **أرسل وثيقتي طارق** (بعد إصلاح سطر 2.2).
6. **round-2:** brief لـ Claude Design لـ 3 شاشات (Interests + إشعارات المستخدم + إشعارات الخطّابة) — الجرد جاهز `round2_inventory.md` → ثم تنفيذ plan-first المعتاد.
7. **حارس status:0 opt-in لـ Bucket A** (affiliate `getSummary`/`getCommissions`) — صغير، غير مبدوء، يُدمج في جولة جودة لاحقة.
8. **استضِف `docs/legal/account_deletion.html`** (مطلوب لروابط metadata المتجرين). ~~احذف `logo_qeran.json` القديم~~ — ✅ محذوف، `logo_qeran_v3.json` هو الوحيد المتبقّي.

**مراحل لاحقة:**
- **لوحة الإحالة (affiliate) المالية للخطّابة** — **UI مبنيّ على عقد طارق الحيّ (`6deb24d`):** كرت نسبة العمولة + كرتا عدّاد. المتبقّي = حارس status:0 (Bucket A) + أي endpoints/شاشات إحالة إضافية (تاريخ العمولات المرقّم).
- **case-status follow-up (كود comment):** refresh() غير-حاجب اختياري عند فتح التفاصيل لاستباق stale-at-open حين يُفوَّت حدث realtime والـ socket كان نائماً (نادر؛ استرداد `INVALID_STATUS_TRANSITION` الرشيق يغطّيه اليوم).
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

### 📜 عقد الباك إند الكامل (طارق — **حيّ الآن**، استُلم هذه الجلسة)

- **الغلاف** `{status, data, message, errorCode}`؛ **استثناء:** `/subscriptions/plans` و `/subscriptions/current` يرجعان **RAW** (بلا غلاف). `/current` يرجّع **204 No Content** لمّا لا اشتراك نشط.
- **`-1` = لامحدود في كل مكان** (حدود الباقة **و** العدّادات المتبقّية).
- **التواريخ الآن ISO 8601 UTC مع `Z`** (طارق أصلحها؛ حارس `hasTz` بـ `server_datetime.dart` يصير no-op مع وجود `Z` — سليم أماماً).
- **payload الباقة:** `tier` (0=Free · 1=Basic · 2=VIP — **للتعريف/الهبوط، لا تطابق بالاسم أبداً**) · `isFree` · `features{}` (`-1`=لامحدود) · `featuresAr/featuresEn` (نقاط عرض) · `pricings[]` (`isPopular` على VIP-3شهور = الاختيار الافتراضي).
- **الحدود:** **Basic == Free تماماً** (50 إعجاب · ∞ اهتمامات · 5 تبادلات صور · ∞ مشاهدات يومية). VIP كله لامحدود. **الاهتمامات الجادّة لامحدودة للجميع.** حدّ المشاهدات اليومية **يطبَّق فقط على مستخدمي بلا-اشتراك** (افتراضي 10/يوم)؛ المشتركون لا يُحدّون أبداً.
- **التصفير:** الإعجابات وتبادل الصور تُصفَّر عند `expiresAt` (فترة الفوترة — صف اشتراك جديد بعدّادات=0 عند التجديد)؛ المشاهدات اليومية عند **منتصف ليل UTC** (`resetAt` داخل `DAILY_VIEWS_EXCEEDED`.data).
- **errorCodes المُبوَّبة الحيّة:** `SUBSCRIPTION_REQUIRED` · `LIKES_QUOTA_EXCEEDED` · `DAILY_VIEWS_EXCEEDED` (على `GET /Discovery`، **بلا-اشتراك فقط**، `data.resetAt` = «عُد غداً» **لا paywall**) · `PHOTO_EXCHANGE_LIMIT_REACHED` (مشترك عند السقف → **ترقية**). الباقة المجانية **مرّة واحدة لكل مستخدم** (server-enforced). إشعار الإعجاب يحترم اشتراك **المستقبِل**. المحادثات تبقى مفتوحة بعد الانتهاء.
- **العرض يستخدم `storeProduct.priceString`** — لا `price` (USD الإداري) أبداً.

### 🛡️ عقد إطلاق المتجر (طارق — مُسلَّم هذه الجلسة، store-launch/UGC)

كله مُغلَّف `{status:1|0, data, message, errorCode}`؛ **صنّف على errorCode لا الرسالة العربية؛ per-datasource Bucket A، لا حارس مركزي.**
- **`POST /api/reports`** — body `{targetUserId?, targetContentId?, reason, note?}`؛ `reason` enum: `InappropriateContent|Impersonation|Harassment|Scam|FalseInformation|Other` (تطابق case-insensitive)؛ نجاح `data`=reportId؛ errorCode `VALIDATION_ERROR`/`TARGET_USER_NOT_FOUND`.
- **`/api/block`** (`POST {targetUserId}` / `DELETE /{id}` / `GET`) — **دلالات teardown كامل server-side** (المحظور يختفي من الديسكفري/الماتشات، وأي إعجاب/ماتش/محادثة قائمة تُصرَم)؛ الأكشن ضد محظور يرجع `TARGET_USER_NOT_FOUND` **محايداً — الـ UI يجب ألّا يكشف حالة الحظر أبداً**.
- **العمر 18+:** مُطبَّق في مسار submit-answers → `UNDERAGE_NOT_ALLOWED` عند ميلاد <18. العميل يقصّ الـ picker لـ 18+ **و** يعالج الكود على الإرسال.
- **`DELETE /api/matchmaker/me/account`** — حذف دائم للـ Moderator (يطابق حذف المستخدم).
- **Takedown:** لوحة أدمن فقط — **لا endpoint محمول**.
- **حسابات مراجعة:** دخول email/password يعمل؛ **حسابان (مستخدم + Moderator) ببيانات واقعية لسا يجب إنشاؤهما وإبقاؤهما حيّين** (طارق).
- **الاستضافة (أعلى حاجب):** base URL ينتقل عن `rtempurl` لاستضافة مدفوعة ثابتة؛ **أنس يأخذ الجديد قبل البناء الإصداري** (سطر واحد + rebuild).

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
- **الحدود/الاشتراك (عقد طارق الحيّ — احترمها):**
  - **`-1` = لامحدود في كل مكان** (حدود + عدّادات) — sentinel وحيد؛ `v < 0`. لا `int.MaxValue`.
  - **تعريف الباقة بالـ `tier` (0/1/2) لا بالاسم** — الاسم للعرض فقط (P2 يحذف تطابق الاسم).
  - **نبرة حدّ تبادل الصور = «ترقية» لا «اشترك»** (المشترك يدفع أصلاً) — sheet مخصّص `PhotoExchangeLimitSheet`، **لا** إثقال الـ paywall.
  - **حدّ المشاهدات اليومية = لمستخدمي بلا-اشتراك فقط** — شاشة «عُد غداً» بعدّاد `resetAt` (منتصف ليل UTC)، **لا paywall**.
  - **العرض بـ `storeProduct.priceString`** لا `price` الإداري (USD).
  - **عملة الإحالة (affiliate) = حقل باك إند، دائماً USD** — تُعرَض من الحقل لا تُحوَّل ولا تُخفى؛ `commissionType` (`percent`/`fixed`) **forward-safe** (مجهول/فارغ → `null` → «—»).
- **حقل `status` مُثقَل — لا حارس مركزي:** success/failure مقابل قيمة عمل الخطّابة مقابل مُعشَّش في `data`؛ الحارس المركزي **مرفوض**، و«200-مع-status:0» يُعالَج per-datasource (Bucket A فقط). (التفصيل + تصنيف الدلاء الثلاثة بالـ Gotchas.) **موجة أمان الإطلاق التزمت به:** Report/Block/questionnaire صنّفوا على errorCode per-datasource؛ `http_consumer`/`api_response`/`errors` **لم تُمَسّ**.
- **أمان الإطلاق (UGC — احترمها):**
  - **Block محايد دائماً:** `TARGET_USER_NOT_FOUND` يُعامَل «غير متاح» ولا يكشف حالة الحظر أبداً (لا «حظرتَه/حظرك» بأي UI/toast/state). teardown محلي عبر `refresh()` على block-return لا mutation هشّ للـ deck.
  - **مداخل Report/Block = discovery (⋮ البروفايل) + معرض الماتش (بلاغ) + الإعدادات (المحظورون)** — **لا أكشن داخل chat** (القرار المتّفق).
  - **`reason` enum يطابق طارق حرفياً** (`InappropriateContent|Impersonation|Harassment|Scam|FalseInformation|Other`) — أي تباين = رفض صامت من الباك إند.
  - **`usesCleartextTraffic=false`:** كل نداء/صورة يجب أن يكون HTTPS؛ أي `http://` يُكسَر.
  - **حذف الحساب per-role:** المستخدم والخطّابة كلاهما له مسار حذف دائم (تأكيد-مكتوب→حذف→unlink→wipe→login)؛ حذف الخطّابة يرقّي الـ deactivate-only القديم.
- **لا تُكوميت أبداً:** `.metadata` · `android/…/MainActivity.kt` · `web/` · `docs/_design/` · `docs/_plan_drafts/PRELAUNCH_PLAN.md` · `docs/legal/account_deletion.html` (تُستضاف منفصلة) · حذوفات `_archive/*.md` · token file (`qeran_colors.dart`) بلا تأكيد · شغل أنس (gender/Interests round-2/الترجمات المعلّقة). (`data.json` صار gitignored.)

---

## ⚠️ Gotchas (تنبيهات)

- **⭐ mojibake بالكونسول (����) ≠ ملف تالف:** stdout الويندوز cp1256 يطبع UTF-8 سليماً غلطاً. تحقّق بـ hexdump أو rootBundle قبل افتراض فساد الملف. **ضيّع وقتاً هذه الجلسة قبل تأكيد سلامة ar.json.**
- **⭐ Hot reload (`r`) لا يعيد تحميل الأصول:** تغييرات الترجمة/JSON تظهر فقط بعد hot **RESTART** (`R` كبيرة) لأن `EasyLocalization.ensureInitialized()` يعمل في `main()` فقط. **كلّف تشخيصاً حين ظهرت مفاتيح جديدة كأسماء خام.**
- **⭐ CODE WINS على الـ handoff** لمّا للكود ميزة حقيقية شغّالة أغفلها الـ handoff (انظر القرارات) — والـ«مكوّن واحد لكل غرض» يغلب المخصّص.
- **رسائل الـ commit بتكذب:** تأكّد من الكود دائماً.
- **⭐ كوميت بعنوان مضلّل ارتدّ بصمت على شغل شاشة تانية:** `6c55f00` بعنوان `fix(subscriptions): enhance RevenueCat…` **رجّع تنسيق `discovery_action_bar.dart` تبع `95cc937`** وخلّى اختباراته — فبقي اختباران فاشلان لدورات كثيرة قبل ما يُكشَف الجذر. لمّا يفشل اختبار على ملف ما لمسته، **`git log -p -- <file>` قبل أي إصلاح**. (نفس الدرس بمقياس أوسع: العمل بالتوازي مع مودل تاني على نفس الملف يحتاج تحقّقاً من الكود لا من العنوان.)
- **⚠️ `Text(maxLines: null, overflow: TextOverflow.ellipsis)` ينهار لسطر واحد** — الـ ellipsis يُطبَّق على أول سطر يتجاوز العرض. الصح: `overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis`. (كان جذر باگ «نبذة عني سطر واحد».)
- **⚠️ خطّ اختبارات الـ widget ليس الخطّ المشحون** — **لا تؤكّد أبداً على قياسات بكسل مطلقة للنص**؛ قارن ارتفاعات نسبية على نفس السطح (اسم طويل مقابل قصير) فيُلغى أثر الخطّ.
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
- **⭐ `-1` = لامحدود في كل مكان** (حدود الباقة **والعدّادات المتبقّية**) — `isUnlimitedRemaining(v) => v < 0`. كان `int.MaxValue` يُعرَض «**-1**» حرفياً لكل مستخدم VIP.
- **⭐ صنّف بالـ errorCode أولاً لا برسالة عربية:** المجموعة الكاملة بـ `error_codes.dart`؛ العربي fallback فقط للاستجابات القديمة بلا كود. **احرس status:0 على المسار 200-الناجح** — إعجاب مُبوَّب راجع HTTP 200 `{status:0}` كان يُقرأ `LikeAccepted(likeId:'')`.
- **⭐ `/current` = 204 لمّا لا اشتراك؛ `/plans` و `/current` RAW بلا غلاف** — لا تفكّ غلافاً غير موجود (استخدم `getRaw`).
- **⭐ حدّ المشاهدات اليومية = لمستخدمي بلا-اشتراك فقط** (`DAILY_VIEWS_EXCEEDED` «عُد غداً» + `data.resetAt`، **لا paywall**)؛ المشتركون لا يُحدّون. حدّ تبادل الصور **للمشترك** عند السقف = **ترقية** لا «اشترك» (sheet مخصّص، لا الـ paywall).
- **⭐⭐ حقل `status` مُثقَل عبر الـ API — لا حارس مركزي أبداً:** في بعض الـ endpoints `status` = نجاح/فشل (`{status:1|0}` غلاف)، لكن بتطبيق **الخطّابة** هو **قيمة عمل** (حالات الحالة: pending/accepted/rejected)، وببعض الـ payloads مُعشَّش داخل `data`. **حارس مركزي «status:0 = خطأ» جُرِّب ورُفض** لأنه يُسيء قراءة قيمة عمل الخطّابة فيكسر ذلك التطبيق. نمط «200-مع-`{status:0}`» يُعالَج **per-datasource (Bucket A فقط)، لا عالمياً أبداً**. تصنيف الدلاء الثلاثة: **Bucket A** (status=نجاح/فشل، يحتاج الحارس) = فقط affiliate `getSummary`/`getCommissions` (+ subscriptions `validateCode`/`getCurrent` بانتظار تأكيد طارق لشكل الغلاف) · **Bucket B** (قيمة عمل / بلا غلاف — `/plans`، `/current`، كل الخطّابة) = **يجب ألّا** يأخذ الحارس · **Bucket C** (غامض) = قرار حالة-بحالة. (`_handleResponse` يحرس `status==1` مركزياً؛ `_handleRawResponse` **لا** يرمي على `status:0` قصداً ليصنّف كل caller نفسه.)
- **⭐ جلستان Claude متوازيتان على نفس الريبو/working tree حرّرتا `ar.json`/`en.json`/`locale_keys.g.dart` معاً:** حُلّت نظيفاً بـ `git add -p` (staging جزئي لمفاتيح كل خيط فقط) + `git diff --cached` قبل الكوميت. **تجنّب تحرير ملفات الترجمة المشتركة بالتوازي دون كوميت بينهما.**
- **⭐ Report/Block بُنيتا FRESH في هذا الريبو:** جلسة ويب موازية بنت نسخة **لم تُدفَع أبداً** — **النسخة داخل الريبو هي الكانونية؛ تجاهل/تخلّص من نسخة جلسة الويب** لتجنّب التباعد.
- **⭐ Lottie الـ splash (v3) — Flutter يتجاهل ميزات AE:** `logo_qeran_v3.json` يحوي **3 تعابير bounce + ~5 تأثيرات Fast Box Blur + 6 track mattes ألفا** يتجاهلها/قد لا يرسمها محرّك Lottie في Flutter — **كشف الـ trim-path (16 trim paths) يشتغل، لكن الـ bounce/glow قد يغيب** (مقبول؛ الـ native splash هو الـ fallback). الـ hang-proofing محفوظ (dual-gate + errorBuilder + timeout 6s + reduce-motion). ✅ `logo_qeran.json` القديم **محذوف** — `logo_qeran_v3.json` هو الـ Lottie الوحيد المتبقّي (مؤكَّد: 19 asset، كلها مرجَّعة).
- **⭐ `git add -A` خطر مع web/+docs/:** الشجرة تحوي `web/` (scaffolding) + `docs/` (تصاميم/خطط/صفحة الحذف) التي **يجب ألّا تُكوميت أبداً** — stage بمسارات صريحة + حارس `git diff --cached --name-only | grep -E '^(web/|docs/)'` قبل كل كوميت (استُخدم في موجة أمان الإطلاق؛ صفر تسرّب).

---

## ⚠️ أعلام التحقّق التشغيلي (على حساب Moderator حيّ — لا شيء يحجب)

- deep-link «الحالات» من الصندوق لتاب الحالات (shell scope للـ route المدفوع).
- أيقونات إشعارات per-action + توجيه `data` معبّأ — يحتاج إشعار **post-fix** + push حقيقي (`adb` لا يحاكي `onMessageOpenedApp`/`getInitialMessage`).
- خيوط الزميلات realtime — تحتاج حسابَي Moderator حيّين.
- سيغمنت الجنس بالاستكشاف يفلتر فعلاً (Male/Female للباك إند).
- تاب «بالانتظار» (Users) — كان 0 مستخدمين؛ نفس مسار كود الكرت.
- نص `matchmaker_users_age_years` = «عندي {age} سنة» (صيغة متكلّم — POV غلط لعرض مستخدم؛ إصلاح صياغة على جهتنا).
