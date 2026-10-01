import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/placement.dart';
import 'package:qeran/features/discovery/domain/entities/placement_code.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card_skeleton.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_merged_profile_body.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_privacy_message.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_title_row.dart';

/// Strings render as their keys.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

void main() {
  testWidgets('image overlay never overflows when viewport height collapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              height: 140,
              child: DiscoveryImagePanel(
                profile: _profile,
                showTitleRow: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('رنا الشمري 22'), findsOneWidget);
    expect(find.text('صاحبة عمل'), findsOneWidget);
  });

  // A small phone held upright gets a 280 pt photo: the title row across its
  // top, the lock in the middle and the name above the intro sheet must still
  // keep apart. One chip: the test font draws every glyph as a wide square,
  // so one chip here is as tall as a full row on a phone.
  testWidgets('on a 280 pt photo the title row, lock and name keep apart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/translations',
        assetLoader: const _StubAssetLoader(),
        child: Builder(
          builder: (ctx) => MaterialApp(
            locale: ctx.locale,
            supportedLocales: ctx.supportedLocales,
            localizationsDelegates: ctx.localizationDelegates,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 375,
                  child: DiscoveryImagePanel(
                    profile: _oneChip,
                    height: kDiscoveryPhotoHeightSmall,
                    onFilterTap: () {},
                    // What the merged card reserves for its intro sheet.
                    bottomContentInset:
                        DiscoveryMergedProfileBody.sheetOverlap +
                        QeranSpacing.s16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(DiscoveryTitleRow));
    final lock = tester.getRect(find.byType(DiscoveryPrivacyMessage));
    final name = tester.getRect(find.text('رنا الشمري 22'));
    expect(row.overlaps(lock), isFalse);
    expect(lock.overlaps(name), isFalse);
  });
}

const _profile = DiscoveryProfile(
  id: 'small-height-profile',
  name: 'رنا الشمري',
  age: 22,
  images: [],
  matchingScore: 0,
  placements: [
    Placement(
      code: PlacementCode.aboveImage,
      name: 'بيانات أساسية',
      items: [
        PlacementItem(
          questionId: 1,
          question: 'العمل',
          type: PlacementItemType.text,
          value: PlacementSingle('employed'),
          display: PlacementSingle('صاحبة عمل'),
        ),
        PlacementItem(
          questionId: 2,
          question: 'الدولة',
          type: PlacementItemType.select,
          value: PlacementSingle('saudi_arabia'),
          display: PlacementSingle('سعودية'),
        ),
        PlacementItem(
          questionId: 3,
          question: 'المدينة',
          type: PlacementItemType.select,
          value: PlacementSingle('riyadh'),
          display: PlacementSingle('الرياض'),
        ),
      ],
    ),
  ],
);

final _oneChip = DiscoveryProfile(
  id: _profile.id,
  name: _profile.name,
  age: _profile.age,
  images: const [],
  matchingScore: 0,
  placements: [
    Placement(
      code: PlacementCode.aboveImage,
      name: 'بيانات أساسية',
      items: [_profile.placements.single.items.first],
    ),
  ],
);
